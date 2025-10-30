#!/bin/bash
# Set the CORE_SCRIPTS_DIR to the directory containing this script.
CORE_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"

# Source the common and registry scripts.
source "$CORE_SCRIPTS_DIR/common.sh"
source "$CORE_SCRIPTS_DIR/env.sh"

if [ -z "$WSL_IP" ]; then
    log ERROR "❌ Error: Could not retrieve the WSL IP address. Aborting."
    exit 1
fi

log INFO "✅ WSL IP obtained: $WSL_IP"
log INFO "✅ Rancher Hostname: $RANCHER_HOSTNAME"
log INFO "--- Starting the installation. 'sudo' will be required multiple times. ---"
log INFO ""

# =================================================================
# 0. PRE-FLIGHT CLEANUP (Added Section)
# =================================================================
log INFO "🧹 0. Running Pre-Flight Cleanup..."

# Check and remove K3s installation if it exists
K3S_UNINSTALL_SCRIPT="/usr/local/bin/k3s-uninstall.sh"
if test -f "$K3S_UNINSTALL_SCRIPT"; then
    log WARN "⚠️ K3s installation found. Executing uninstallation script..."
    sudo "$K3S_UNINSTALL_SCRIPT"
    log INFO "✅ K3s uninstallation complete."
    # Wait a moment to ensure all processes have stopped
    sleep 5
else
    log INFO "✅ No previous K3s installation found. Skipping uninstallation."
fi

# Clean up Docker Registry container if it exists
if docker ps -a | grep -q "registry"; then
    log INFO "🐳 Docker registry container found. Stopping and removing it..."
    docker stop registry
    docker rm registry
    log INFO "✅ Docker registry cleaned up."
else
    log INFO "✅ No previous Docker registry container found."
fi

# Clean up remaining lock files if any previous process failed to clean up
if test -f /var/lib/dpkg/lock-frontend; then
    log WARN "⚠️ Lock file /var/lib/dpkg/lock-frontend found. Removing it..."
    sudo rm /var/lib/dpkg/lock-frontend
fi

if test -f /var/lib/dpkg/lock; then
    log WARN "⚠️ Lock file /var/lib/dpkg/lock found. Removing it..."
    sudo rm /var/lib/dpkg/lock
fi

# Reconfigure dpkg in case a previous installation was interrupted
sudo dpkg --configure -a

log INFO "✅ Pre-Flight Cleanup finished."

# =================================================================
# 1. K3S INSTALLATION
# =================================================================
log INFO "🚀 1. Installing K3s..."
curl -sfL https://get.k3s.io | sh - 

# Wait a moment for K3s to start
log INFO "⏳ Waiting 15 seconds for K3s to start..."
sleep 15

# KUBECONFIG Configuration
log INFO "🛠️ Configuring ~/.kube/config and permissions..."
sudo mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

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
# 3. HELM CHARTS INSTALLATION (CERT-MANAGER & RANCHER)
# =================================================================
log INFO ""
log INFO "📦 3. Installing Cert-Manager and Rancher Manager with Helm..."

# 3.1 Cert-Manager
log INFO "➡️ Installing Cert-Manager..."
helm repo add jetstack https://charts.jetstack.io
helm repo update
kubectl create namespace cert-manager || true
helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.14.0 --set installCRDs=true

# Wait for Cert-Manager Pods to be ready (Max 5 minutes)
log INFO "⏳ Waiting for Cert-Manager to be ready (max 300s)..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s
if [ $? -ne 0 ]; then
    log WARN "⚠️ Warning: Cert-Manager pods took a long time to start. Installation will continue."
fi

# 3.2 Rancher Manager
log INFO "➡️ Installing Rancher Manager..."
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update
kubectl create namespace cattle-system || true
helm install rancher rancher-latest/rancher --namespace cattle-system --set hostname="$RANCHER_HOSTNAME" --set bootstrapPassword=admin

# =================================================================
# 4. NFS SUBDIR PROVISIONER INSTALLATION
# =================================================================
log INFO ""
log INFO "💾 4. Installing the NFS Subdir External Provisioner..."
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update

helm install nfs-client-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --namespace default \
    --set nfs.server="$WSL_IP" \
    --set nfs.path="$NFS_SERVER_PATH" \
    --set storageClass.name=nfs-storage \
    --set storageClass.defaultClass=true \
    --set replicaCount=1

log INFO "✅ StorageClass 'nfs-storage' configured as default."

# =================================================================
# 5. INSECURE DOCKER REGISTRY CONFIGURATION
# =================================================================
log INFO ""
log INFO "🐳 5. Setting up Local Docker Registry (Port 5000) and configuring insecure access..."

# 5.1 Docker Registry
docker run -d -p 5000:5000 --restart=always --name registry registry:2

# 5.2 Configure Insecure Registry for Docker
DOCKER_CONFIG_PATH="/etc/docker/daemon.json"
REGISTRY_URL="$WSL_IP:5000"

# Create or update the Docker daemon.json file
if [ ! -f "$DOCKER_CONFIG_PATH" ]; then
    log INFO "Creating $DOCKER_CONFIG_PATH..."
    echo "{}" | sudo tee "$DOCKER_CONFIG_PATH" > /dev/null
fi

# Use jq to safely update the JSON (assuming it's installed)
if command -v jq &> /dev/null; then
    log INFO "Updating $DOCKER_CONFIG_PATH with '$REGISTRY_URL' ..."
    # Add the insecure registry to the list, creating the list if it doesn't exist.
    
    # --- CORRECCIÓN APLICADA: La expresión jq está ahora en una sola línea. ---
    sudo jq --arg registry "$REGISTRY_URL" '.["insecure-registries"] |= (if . == null then [$registry] else (. | unique) + [$registry] | unique end)' "$DOCKER_CONFIG_PATH" | sudo tee "$DOCKER_CONFIG_PATH" > /dev/null
    
    log INFO "✅ Docker daemon.json updated successfully."
else
    # Fallback if jq is not installed (more basic)
    log WARN "⚠️ Warning: 'jq' not found. Manually edit $DOCKER_CONFIG_PATH if issues arise."
    log WARN "Ensure it contains:"
    log WARN "{ \"insecure-registries\": [ \"$REGISTRY_URL\" ] }"
fi

log INFO "Restarting Docker service..."
sudo systemctl restart docker

# 5.3 Configure Insecure Registry for K3s
K3S_REGISTRY_CONFIG="/etc/rancher/k3s/registries.yaml"
log INFO "📝 Configuring K3s to use the insecure registry at $K3S_REGISTRY_CONFIG..."

REGISTRY_YAML="mirrors:
  \"$REGISTRY_URL\":
    endpoint:
      - \"http://$REGISTRY_URL\""

echo "$REGISTRY_YAML" | sudo tee "$K3S_REGISTRY_CONFIG" > /dev/null

log WARN "❗ K3s needs to be restarted to apply the registry configuration."
log INFO "Restarting K3s service..."
sudo systemctl restart k3s


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
log INFO "🖥️ Rancher Manager is being installed. To access it, edit your Windows 'hosts' file"
log INFO "   (C:\\Windows\\System32\\drivers\\etc\\hosts) and add the following line:"
log INFO "   $WSL_IP $RANCHER_HOSTNAME"
log INFO "   Then, access https://$RANCHER_HOSTNAME"
log INFO ""
log INFO "🔑 To get the initial Rancher password, run:"
log INFO "   kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}{{"\n"}}'"
log INFO ""
log INFO "⚙️ Key Checks:"
log INFO "   - Cert-Manager Pods: kubectl get pods -n cert-manager"
log INFO "   - Rancher Pods: kubectl get pods -n cattle-system"
log INFO "   - NFS Provisioner Pods: kubectl get pods -l app=nfs-client-provisioner"
log INFO "   - Terraform: terraform -version"
log INFO "================================================================="