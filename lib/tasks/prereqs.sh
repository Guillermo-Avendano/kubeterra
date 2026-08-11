#!/bin/bash
set -Eeuo pipefail

TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${TASK_DIR}/../.." && pwd)"
CORE_SCRIPTS_DIR="${ROOT_DIR}/lib"

source "${TASK_DIR}/_env.sh"
load_env
source "${CORE_SCRIPTS_DIR}/common.sh"

detect_os
CURRENT_USER=$(whoami)

log INFO "Installing Docker and prerequisites..."

if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg lsb-release jq dos2unix net-tools

  sudo apt-get remove -y docker docker-engine docker.io containerd runc docker-ce docker-ce-cli containerd.io docker-compose-plugin 2>/dev/null || true

  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  ARCH=$(dpkg --print-architecture)
  CODENAME=$(lsb_release -cs)
  echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
elif [ "$OS" = "rhel" ] || [ "$OS" = "centos" ] || [ "$OS" = "rocky" ] || [ "$OS" = "fedora" ]; then
  sudo dnf install -y dnf-plugins-core jq dos2unix net-tools 2>/dev/null || sudo yum install -y yum-utils jq dos2unix net-tools
  sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo 2>/dev/null || sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin 2>/dev/null || sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
else
  log ERROR "Unsupported OS: $OS"
  exit 1
fi

sudo groupadd docker >/dev/null 2>&1 || true
sudo usermod -aG docker "$CURRENT_USER"
sudo systemctl enable docker
sudo systemctl start docker

if [ -f /usr/libexec/docker/cli-plugins/docker-compose ] && [ ! -e /usr/local/bin/docker-compose ]; then
  sudo ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
elif [ -f /usr/lib/docker/cli-plugins/docker-compose ] && [ ! -e /usr/local/bin/docker-compose ]; then
  sudo ln -s /usr/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
fi

if [ "$OS" = "ubuntu" ]; then
  log INFO "Ubuntu detected: kubectl and helm will be provided by MicroK8s (installed via './kubeterra.sh cluster')."
else
  log INFO "Installing kubectl..."
  curl -LO https://dl.k8s.io/release/v1.33.0/bin/linux/amd64/kubectl
  sudo install kubectl /usr/local/bin/kubectl
  rm -f kubectl

  if [ ! -f "${CORE_SCRIPTS_DIR}/get_helm.sh" ]; then
    curl -fsSL -o "${CORE_SCRIPTS_DIR}/get_helm.sh" https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  fi
  chmod +x "${CORE_SCRIPTS_DIR}/get_helm.sh"
  "${CORE_SCRIPTS_DIR}/get_helm.sh"
fi

log INFO "Installing yq..."
sudo wget -q https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
sudo chmod +x /usr/local/bin/yq

log INFO "Prerequisites installed successfully. Run 'newgrp docker' if docker permissions are not yet active."
