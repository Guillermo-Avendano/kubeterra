#!/bin/bash
# Set the CORE_SCRIPTS_DIR to the directory containing this script.
CORE_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"

export LOCAL_REGISTRY_PORT="32000"

# Source the common and registry scripts.
# NOTE: Assuming 'log' function is defined in common.sh
source "$CORE_SCRIPTS_DIR/common.sh"
source "$CORE_SCRIPTS_DIR/env.sh"

if ! command -v snap &> /dev/null; then
    log ERROR "❌ Error: 'snap' command not found. MicroK8s requires Snap. Aborting."
    exit 1
fi

if [ -z "$WSL_IP" ]; then
    log ERROR "❌ Error: Could not retrieve the WSL IP address. Aborting."
    exit 1
fi


REGISTRY_PORT=$LOCAL_REGISTRY_PORT

log INFO "✅ WSL IP obtained: $WSL_IP"
log INFO "✅ Registry Port requested: $REGISTRY_PORT"
log INFO "--- Starting the installation. 'sudo' will be required multiple times. ---"
log INFO ""

# =================================================================
# 0. PRE-FLIGHT CLEANUP
# =================================================================
log INFO "🧹 0. Running Pre-Flight Cleanup..."

# Check and remove MicroK8s installation if it exists
if snap list | grep -q "microk8s"; then
    log WARN "⚠️ MicroK8s installation found. Executing uninstallation..."
    sudo snap remove microk8s --purge
    log INFO "✅ MicroK8s uninstallation complete. Waiting 10s..."
    sleep 10
else
    log INFO "✅ No previous MicroK8s installation found. Skipping uninstallation."
fi

# Clean up Docker Registry container (if it was run standalone previously)
if docker ps -a | grep -q "registry"; then
    log INFO "🐳 Docker registry container found. Stopping and removing it..."
    docker stop registry
    docker rm registry
    log INFO "✅ Docker registry cleaned up."
else
    log INFO "✅ No previous Docker registry container found."
fi

# Lock file cleanup
if test -f /var/lib/dpkg/lock-frontend; then
    sudo rm /var/lib/dpkg/lock-frontend
fi
if test -f /var/lib/dpkg/lock; then
    sudo rm /var/lib/dpkg/lock
fi
sudo dpkg --configure -a

log INFO "✅ Pre-Flight Cleanup finished."

# =================================================================
# 1. MICROK8S INSTALLATION & ADDONS
# =================================================================
log INFO "🚀 1. Installing MicroK8s..."

sudo apt update # Ensure apt is updated for packages in section 2
sudo snap install microk8s --classic 
sudo usermod -a -G microk8s $USER
log INFO "👥 User '$USER' added to 'microk8s' group."
sudo snap alias microk8s.kubectl kubectl

# Wait for MicroK8s to be ready
log INFO "⏳ Waiting for MicroK8s to be ready (max 60s)..."
sudo microk8s status --wait-ready

# Enable required addons (DNS, Helm3, Registry)
log INFO "➕ Enabling MicroK8s addons (DNS, Helm3, Registry: $REGISTRY_URL)..."
sudo microk8s enable dns
sudo microk8s enable helm3

sudo snap alias microk8s.helm3 helm

# Configure and Enable Registry on port 5000
log INFO "➕ Enabling Registry addon ..."
sudo microk8s enable registry

log INFO "⏳ Waiting for addons to be ready (max 60s)..."
sudo microk8s status --wait-ready

# KUBECONFIG Configuration
log INFO "🛠️ Configuring ~/.kube/config and permissions..."
mkdir -p ~/.kube
sudo microk8s config > ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
sudo chown -f -R $USER ~/.kube

# =================================================================
# 2. NFS SERVER INSTALLATION (on WSL)
# =================================================================
log INFO ""
log INFO "💾 2. Installing and configuring the NFS Server..."

# 1. Update packages and install NFS server/client components
sudo apt update
sudo apt install -y nfs-common nfs-kernel-server

# 2. Create and configure the directory to be exported
log INFO "📁 Creating and configuring the exported directory $NFS_SERVER_PATH"
sudo mkdir -p "$NFS_SERVER_PATH"
# Establecer 'nobody:nogroup' es crucial para 'no_root_squash' y evitar problemas de ID mapping.
sudo chown nobody:nogroup "$NFS_SERVER_PATH"
sudo chmod 777 "$NFS_SERVER_PATH"

# 3. Determine the subnet for NFS (e.g., 172.24.226.0/20)
# Usaremos el /16 de la WSL_IP por simplicidad, lo cual es común en entornos de desarrollo/WSL.
SUBNET=$(echo "$WSL_IP" | awk -F. '{print $1"."$2".0.0/16"}') 

# 4. Configure /etc/exports - CONDICIONAL
EXPORTS_LINE="$NFS_SERVER_PATH 127.0.0.1(rw,sync,no_subtree_check,no_root_squash,insecure) $SUBNET(rw,sync,no_subtree_check,no_root_squash,insecure)"
log INFO "📝 Checking if export line exists: $EXPORTS_LINE"

# Verifica si la línea EXPORTS_LINE (o el NFS_SERVER_PATH) ya está en /etc/exports
if ! grep -q "^$NFS_SERVER_PATH " /etc/exports; then
    log INFO "➡️ Appending export line: $EXPORTS_LINE"
    echo "$EXPORTS_LINE" | sudo tee -a /etc/exports > /dev/null
else
    log INFO "ℹ️ Export line for $NFS_SERVER_PATH already exists. Skipping append."
fi

# 5. Restart the NFS server to load new configuration
sudo systemctl restart nfs-kernel-server

# 6. Basic mount verification
log INFO "🔍 Verifying NFS locally (using $WSL_IP):"
sudo mkdir -p "$NFS_MOUNT_CHECK_DIR"

if sudo mount -t nfs "$WSL_IP:$NFS_SERVER_PATH" "$NFS_MOUNT_CHECK_DIR"; then
    log INFO "✅ NFS test mount successful to $NFS_MOUNT_CHECK_DIR. Unmounting..."
    sudo umount "$NFS_MOUNT_CHECK_DIR"
    sudo rm -r "$NFS_MOUNT_CHECK_DIR"
else
    # Si el montaje falla, intenta mostrar el estado de los exports para ayudar en el diagnóstico
    log ERROR "❌ Error during NFS mount test. Check firewall or /etc/exports configuration. Aborting."
    log ERROR "Current active NFS exports (sudo exportfs -v):"
    sudo exportfs -v
    exit 1
fi

# =================================================================
# 3. NFS SUBDIR PROVISIONER INSTALLATION
# =================================================================
log INFO ""
log INFO "💾 3. Installing the CSI Driver..."
sudo helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
sudo helm repo update

sudo helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs \
    --namespace kube-system \
    --set kubeletDir=/var/snap/microk8s/common/var/lib/kubelet

kubectl wait pod --selector app.kubernetes.io/name=csi-driver-nfs --for condition=ready --namespace kube-system     

log INFO "✅ StorageClass 'nfs-csi' configured."

# =================================================================
# 4. INSECURE DOCKER REGISTRY CONFIGURATION (Port 5000)
# =================================================================
log INFO ""
log INFO "🐳 4. Configuring local Docker for insecure access (Registry on $REGISTRY_URL)..."

# 4.1 Configure Insecure Registry for Docker (Host)
if [ ! -f "$DOCKER_CONFIG_PATH" ]; then
    log INFO "Creating $DOCKER_CONFIG_PATH..."
    sudo mkdir -p "$(dirname "$DOCKER_CONFIG_PATH")"
    echo "{}" | sudo tee "$DOCKER_CONFIG_PATH" > /dev/null
fi

# Attempt to update the config using jq
if command -v jq &> /dev/null; then
    log INFO "Updating $DOCKER_CONFIG_PATH with '$REGISTRY_URL' using jq..."
    sudo jq --arg registry "$REGISTRY_URL" '.["insecure-registries"] |= (if . == null then [$registry] else (. | unique) + [$registry] | unique end)' "$DOCKER_CONFIG_PATH" | sudo tee "$DOCKER_CONFIG_PATH" > /dev/null
    log INFO "✅ Docker daemon.json updated successfully."
else
    log WARN "⚠️ Warning: 'jq' not found. Cannot automatically update daemon.json."
    log WARN "   Manually ensure $DOCKER_CONFIG_PATH contains: { \"insecure-registries\": [ \"$REGISTRY_URL\" ] }"
fi

log INFO "Restarting Docker service..."
sudo systemctl restart docker

# 4.2 Verification of Insecure Registry Configuration
log INFO "🔍 Verifying 'insecure-registries' configuration in daemon.json..."

# Check if the registry URL is present in the configuration file
if sudo cat "$DOCKER_CONFIG_PATH" | grep -q "\"$REGISTRY_URL\""; then
    log INFO "✅ Verification successful: '$REGISTRY_URL' found in $DOCKER_CONFIG_PATH."
else
    log ERROR "❌ Verification FAILED: '$REGISTRY_URL' not found in $DOCKER_CONFIG_PATH."
    log ERROR "   This will prevent 'docker push/pull' to the local MicroK8s registry."
    log ERROR "   Please install 'jq' (sudo apt install jq) or edit the file manually."
    # Optionally exit here if this is a critical requirement
fi

# 4.3 MicroK8s Registry Configuration
log INFO "📝 MicroK8s registry is running on port $REGISTRY_PORT and configured automatically via addon."

# =================================================================
# 5. NFS STORAGECLASS CREATION
# =================================================================
log INFO ""
log INFO "💾 6. Creating the NFS StorageClass for dynamic provisioning..."

# Definición del manifiesto YAML para la StorageClass
# Usamos el WSL_IP como 'server' y la ruta NFS_SERVER_PATH como 'share'.
NFS_STORAGE_CLASS_YAML=$(cat <<EOF
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-csi
provisioner: nfs.csi.k8s.io
parameters:
  server: $WSL_IP
  share: $NFS_SERVER_PATH
reclaimPolicy: Delete
volumeBindingMode: Immediate
mountOptions:
  # Opciones comunes, ajusta si tu servidor NFS usa una versión diferente.
  - hard
  - nfsvers=4.1
EOF
)

log INFO "📝 Applying StorageClass 'nfs-csi' using server: $WSL_IP and share: $NFS_SERVER_PATH"

# Aplicar el manifiesto directamente con kubectl
echo "$NFS_STORAGE_CLASS_YAML" | kubectl apply -f -

# Verificar que la StorageClass se haya creado
if kubectl get storageclass nfs-csi &> /dev/null; then
    log INFO "✅ StorageClass 'nfs-csi' created successfully."
else
    log ERROR "❌ Error: Could not verify the creation of StorageClass 'nfs-csi'. Aborting."
    exit 1
fi

# =================================================================
# 6. Install Terraform
# =================================================================
sudo apt update
sudo apt install -y wget unzip

wget https://releases.hashicorp.com/terraform/1.11.2/terraform_1.11.2_linux_amd64.zip

unzip terraform_1.11.2_linux_amd64.zip

sudo mv terraform /usr/local/bin/

rm ./terraform_1.11.2_linux_amd64.zip

# =================================================================
# 7. FINAL SUMMARY
# =================================================================
log INFO ""
log INFO "================================================================="
log INFO "🎉 INSTALLATION COMPLETE! 🎉"
log INFO "================================================================="
log INFO "🌐 WSL IP: $WSL_IP"
log INFO "🔥 MicroK8s is running and ready to use."
log INFO "🐳 Local Registry: $REGISTRY_URL"
log INFO ""
log INFO "⚙️ Key Checks:"
log INFO "    - MicroK8s Status: sudo microk8s status"
log INFO "    - StorageClass: kubectl get storageclass (Should show 'nfs-csi')"
log INFO "    - CSI Driver Pods: kubectl get pods -l app.kubernetes.io/name=csi-driver-nfs -n kube-system"
log INFO "    - Terraform: terraform -version"
log INFO "    - Registry Pods: kubectl get all -n container-registry"
log INFO "================================================================="
