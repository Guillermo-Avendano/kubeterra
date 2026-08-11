#!/bin/bash
set -Eeuo pipefail

TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${TASK_DIR}/../.." && pwd)"
CORE_SCRIPTS_DIR="${ROOT_DIR}/lib"

source "${TASK_DIR}/_env.sh"
load_env
source "${CORE_SCRIPTS_DIR}/common.sh"

detect_os
WSL_IP="${WSL_IP:-$(get_wsl_ip)}"
RANCHER_HOSTNAME="${RANCHER_HOSTNAME:-rancher.local}"
NFS_SERVER_PATH="${NFS_SERVER_PATH:-/srv/nfs/kubedata}"
NFS_MOUNT_CHECK_DIR="${NFS_MOUNT_CHECK_DIR:-/tmp/kubeterra-nfs-check}"
MICROK8S_CHANNEL="${MICROK8S_CHANNEL:-1.30/stable}"
MICROK8S_REGISTRY_SIZE="${MICROK8S_REGISTRY_SIZE:-20Gi}"

if [ -z "${WSL_IP}" ]; then
  log ERROR "Could not determine WSL IP. Set WSL_IP in .env"
  exit 1
fi

# Installs and exports the host NFS server, shared by both the K3s and MicroK8s paths.
setup_nfs_server() {
  if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
    sudo apt update
    sudo apt install -y nfs-common nfs-kernel-server
  elif [ "$OS" = "rhel" ] || [ "$OS" = "centos" ] || [ "$OS" = "rocky" ] || [ "$OS" = "fedora" ]; then
    sudo dnf install -y nfs-utils || sudo yum install -y nfs-utils
    sudo systemctl enable --now rpcbind
    sudo systemctl enable --now nfs-server
  else
    log ERROR "Unsupported OS: $OS"
    exit 1
  fi

  sudo mkdir -p "$NFS_SERVER_PATH"
  sudo chmod 777 "$NFS_SERVER_PATH"
  SUBNET=$(echo "$WSL_IP" | awk -F. '{print $1"."$2".0.0/16"}')
  EXPORTS_LINE="$NFS_SERVER_PATH 127.0.0.1(rw,sync,no_subtree_check,no_root_squash,insecure) $SUBNET(rw,sync,no_subtree_check,no_root_squash,insecure)"
  if ! grep -q "^$NFS_SERVER_PATH " /etc/exports; then
    echo "$EXPORTS_LINE" | sudo tee -a /etc/exports >/dev/null
  fi

  if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
    sudo systemctl restart nfs-kernel-server
  else
    sudo systemctl restart nfs-server
  fi

  sudo mkdir -p "$NFS_MOUNT_CHECK_DIR"
  sudo mount -t nfs "$WSL_IP:$NFS_SERVER_PATH" "$NFS_MOUNT_CHECK_DIR"
  sudo umount "$NFS_MOUNT_CHECK_DIR"
  sudo rm -rf "$NFS_MOUNT_CHECK_DIR"
}

# Points bare `kubectl`/`helm` calls (used by the rest of kubeterra's scripts) at MicroK8s,
# and defines the equivalent aliases for interactive shells as requested.
setup_microk8s_kube_tools() {
  sudo tee /usr/local/bin/kubectl >/dev/null <<'EOF'
#!/bin/bash
exec microk8s kubectl "$@"
EOF
  sudo chmod +x /usr/local/bin/kubectl

  sudo tee /usr/local/bin/helm >/dev/null <<'EOF'
#!/bin/bash
exec microk8s helm3 "$@"
EOF
  sudo chmod +x /usr/local/bin/helm

  local bashrc="$HOME/.bashrc"
  if ! grep -q "kubeterra: microk8s aliases" "$bashrc" 2>/dev/null; then
    cat >>"$bashrc" <<'EOF'

# kubeterra: microk8s aliases
alias kubectl='microk8s kubectl'
alias helm='microk8s helm3'
EOF
  fi

  mkdir -p "$HOME/.kube"
  microk8s config >"$HOME/.kube/config"
}

bootstrap_microk8s() {
  log INFO "Bootstrapping MicroK8s, NFS and local registry..."

  if ! command_exists microk8s; then
    sudo snap install microk8s --classic --channel="$MICROK8S_CHANNEL"
  else
    log INFO "MicroK8s already installed, skipping snap install."
  fi

  sudo usermod -aG microk8s "$(whoami)"
  sudo microk8s status --wait-ready

  microk8s enable dns
  microk8s enable "registry:size=${MICROK8S_REGISTRY_SIZE}"

  setup_microk8s_kube_tools
  setup_nfs_server

  helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/ >/dev/null 2>&1 || true
  helm repo update

  helm upgrade --install nfs-client-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --namespace default \
    --set nfs.server="$WSL_IP" \
    --set nfs.path="$NFS_SERVER_PATH" \
    --set storageClass.name=nfs-storage \
    --set storageClass.defaultClass=true \
    --set replicaCount=1

  log INFO "MicroK8s bootstrap completed."
  log INFO "Local registry available at localhost:32000. Set LOCAL_REGISTRY_PORT=32000 in .env to use it."
  log INFO "Run 'newgrp microk8s' (or re-login) if 'kubectl'/'helm' report permission errors."
}

bootstrap_k3s_rancher() {
  log INFO "Bootstrapping K3s cluster, NFS, Rancher and local registry..."

  curl -sfL https://get.k3s.io | sh -
  sudo mkdir -p ~/.kube
  sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
  sudo chown "$(id -u):$(id -g)" ~/.kube/config

  setup_nfs_server

  helm repo add jetstack https://charts.jetstack.io >/dev/null 2>&1 || true
  helm repo add rancher-latest https://releases.rancher.com/server-charts/latest >/dev/null 2>&1 || true
  helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/ >/dev/null 2>&1 || true
  helm repo update

  kubectl create namespace cert-manager >/dev/null 2>&1 || true
  helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.14.0 --set installCRDs=true

  kubectl create namespace cattle-system >/dev/null 2>&1 || true
  helm upgrade --install rancher rancher-latest/rancher --namespace cattle-system --set hostname="$RANCHER_HOSTNAME" --set bootstrapPassword=admin

  helm upgrade --install nfs-client-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --namespace default \
    --set nfs.server="$WSL_IP" \
    --set nfs.path="$NFS_SERVER_PATH" \
    --set storageClass.name=nfs-storage \
    --set storageClass.defaultClass=true \
    --set replicaCount=1

  docker rm -f registry >/dev/null 2>&1 || true
  docker run -d -p 5000:5000 --restart=always --name registry registry:2

  DOCKER_CONFIG_PATH="/etc/docker/daemon.json"
  REGISTRY_URL="${WSL_IP}:5000"
  if [ ! -f "$DOCKER_CONFIG_PATH" ]; then
    echo "{}" | sudo tee "$DOCKER_CONFIG_PATH" >/dev/null
  fi

  if command -v jq >/dev/null 2>&1; then
    sudo jq --arg registry "$REGISTRY_URL" '."insecure-registries" |= (if . == null then [$registry] else (. + [$registry] | unique) end)' "$DOCKER_CONFIG_PATH" | sudo tee "$DOCKER_CONFIG_PATH" >/dev/null
  fi
  sudo systemctl restart docker

  sudo mkdir -p /etc/rancher/k3s
  cat <<EOF | sudo tee /etc/rancher/k3s/registries.yaml >/dev/null
mirrors:
  "$REGISTRY_URL":
    endpoint:
      - "http://$REGISTRY_URL"
EOF
  sudo systemctl restart k3s

  log INFO "Cluster bootstrap completed."
  log INFO "Add this to Windows hosts file: ${WSL_IP} ${RANCHER_HOSTNAME}"
}

if [ "$OS" = "ubuntu" ]; then
  bootstrap_microk8s
elif [ "$OS" = "debian" ] || [ "$OS" = "rhel" ] || [ "$OS" = "centos" ] || [ "$OS" = "rocky" ] || [ "$OS" = "fedora" ]; then
  bootstrap_k3s_rancher
else
  log ERROR "Unsupported OS: $OS"
  exit 1
fi

