#!/bin/bash
# Set the CORE_SCRIPTS_DIR to the directory containing this script.
CORE_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"

# Source the common and registry scripts.
source "$CORE_SCRIPTS_DIR/common.sh"

# Function to get the IP address of the WSL2 instance
get_wsl_ip() {
    # Searches for the IP of the eth0 interface or the first non-loopback IP
    hostname -I | awk '{print $1}'
}

# --- GLOBAL VARIABLES ---
WSL_IP=$(get_wsl_ip)
NFS_SERVER_PATH="$HOME/mobius_data"

# Definir el puerto de Registry solicitado
REGISTRY_PORT="5000"

if ! command -v snap &> /dev/null; then
    log ERROR "❌ Error: 'snap' command not found. MicroK8s requires Snap. Aborting."
    exit 1
fi

if [ -z "$WSL_IP" ]; then
    log ERROR "❌ Error: Could not retrieve the WSL IP address. Aborting."
    exit 1
fi

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
log INFO "➕ Enabling MicroK8s addons (DNS, Helm3, Registry: $WSL_IP:$REGISTRY_PORT)..."
sudo microk8s enable dns
sudo microk8s enable helm3

# Configure and Enable Registry on port 5000
log INFO "➕ Enabling Registry addon on port $REGISTRY_PORT..."
sudo microk8s enable registry:$WSL_IP:$REGISTRY_PORT

# IMPORTANT: Disable 'storage' addon to rely on NFS Subdir Provisioner
log INFO "➖ Disabling 'storage' addon to use NFS Provisioner."
sudo microk8s disable storage

log INFO "⏳ Waiting for addons to be ready (max 60s)..."
sudo microk8s status --wait-ready

# KUBECONFIG Configuration
log INFO "🛠️ Configuring ~/.kube/config and permissions..."
mkdir -p ~/.kube
sudo microk8s config > ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# =================================================================
# 2. NFS SERVER INSTALLATION (on WSL)
# =================================================================
log INFO ""
log INFO "💾 2. Installing and configuring the NFS Server..."

# apt update was moved to section 1 to optimize.
sudo apt install -y nfs-common nfs-kernel-server

log INFO "📁 Creating and configuring the exported directory $NFS_SERVER_PATH"
sudo mkdir -p "$NFS_SERVER_PATH"
sudo chown nobody:nogroup "$NFS_SERVER_PATH"
sudo chmod 777 "$NFS_SERVER_PATH"

SUBNET=$(echo "$WSL_IP" | awk -F. '{print $1"."$2".0.0/16"}')  
EXPORTS_LINE="$NFS_SERVER_PATH 127.0.0.1(rw,sync,no_subtree_check,no_root_squash,insecure) $SUBNET(rw,sync,no_subtree_check,no_root_squash,insecure)"
log INFO "📝 Appending export line: $EXPORTS_LINE"
echo "$EXPORTS_LINE" | sudo tee -a /etc/exports > /dev/null

sudo systemctl restart nfs-kernel-server

log INFO "🔍 Verifying NFS locally (using $WSL_IP):"
sudo mkdir -p "$NFS_MOUNT_CHECK_DIR"
if sudo mount -t nfs "$WSL_IP:$NFS_SERVER_PATH" "$NFS_MOUNT_CHECK_DIR"; then
    log INFO "✅ NFS test mount successful to $NFS_MOUNT_CHECK_DIR. Unmounting..."
    sudo umount "$NFS_MOUNT_CHECK_DIR"
    sudo rm -r "$NFS_MOUNT_CHECK_DIR"
else
    log ERROR "❌ Error during NFS mount test. Check firewall or /etc/exports configuration. Aborting."
    exit 1
fi

# =================================================================
# 3. NFS SUBDIR PROVISIONER INSTALLATION
# =================================================================
log INFO ""
log INFO "💾 3. Installing the NFS Subdir External Provisioner..."
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update

sudo helm install nfs-client-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --namespace default \
    --set nfs.server="$WSL_IP" \
    --set nfs.path="$NFS_SERVER_PATH" \
    --set storageClass.name=nfs-storage \
    --set storageClass.defaultClass=true \
    --set replicaCount=1

log INFO "✅ StorageClass 'nfs-storage' configured as default."

# =================================================================
# 4. INSECURE DOCKER REGISTRY CONFIGURATION (Port 5000)
# =================================================================
log INFO ""
log INFO "🐳 4. Configuring local Docker for insecure access (Registry on $WSL_IP:$REGISTRY_PORT)..."

# 4.1 Configure Insecure Registry for Docker (Host)
DOCKER_CONFIG_PATH="/etc/docker/daemon.json"
REGISTRY_URL="$WSL_IP:$REGISTRY_PORT"

if [ ! -f "$DOCKER_CONFIG_PATH" ]; then
    log INFO "Creating $DOCKER_CONFIG_PATH..."
    echo "{}" | sudo tee "$DOCKER_CONFIG_PATH" > /dev/null
fi

if command -v jq &> /dev/null; then
    log INFO "Updating $DOCKER_CONFIG_PATH with '$REGISTRY_URL' ..."
    sudo jq --arg registry "$REGISTRY_URL" '.["insecure-registries"] |= (if . == null then [$registry] else (. | unique) + [$registry] | unique end)' "$DOCKER_CONFIG_PATH" | sudo tee "$DOCKER_CONFIG_PATH" > /dev/null
    log INFO "✅ Docker daemon.json updated successfully."
else
    log WARN "⚠️ Warning: 'jq' not found. Manually edit $DOCKER_CONFIG_PATH if issues arise."
    log WARN "Ensure it contains: { \"insecure-registries\": [ \"$REGISTRY_URL\" ] }"
fi

log INFO "Restarting Docker service..."
sudo systemctl restart docker

# 4.2 MicroK8s Registry Configuration
log INFO "📝 MicroK8s registry is running on port $REGISTRY_PORT and configured automatically via addon."

# =================================================================
# 5. FINAL SUMMARY
# =================================================================
log INFO ""
log INFO "================================================================="
log INFO "🎉 INSTALLATION COMPLETE! 🎉"
log INFO "================================================================="
log INFO "🌐 WSL IP: $WSL_IP"
log INFO "🔥 MicroK8s está funcionando y listo para usar."
log INFO "🐳 Local Registry: $WSL_IP:$REGISTRY_PORT"
log INFO ""
log INFO "⚙️ Key Checks:"
log INFO "   - MicroK8s Status: sudo microk8s status"
log INFO "   - StorageClass: kubectl get storageclass (Should show 'nfs-storage' as default)"
log INFO "   - NFS Provisioner Pods: kubectl get pods -l app=nfs-client-provisioner"
log INFO "   - Registry Pods: kubectl get all -n container-registry"
log INFO "================================================================="