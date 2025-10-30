#!/bin/bash
# Source the common and registry scripts.
# NOTE: Assuming 'log' function is defined in common.sh
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CORE_DIR/common.sh"

# --- GLOBAL VARIABLES ---
WSL_IP=$(get_wsl_ip)
NFS_SERVER_PATH="$HOME/mobius_data"
NFS_MOUNT_CHECK_DIR="/mnt/nfscheck"

# Define the requested Registry port
REGISTRY_PORT="5000"
REGISTRY_URL="$WSL_IP:$REGISTRY_PORT" # Defined here for use in verification

# Docker configuration file
DOCKER_CONFIG_PATH="/etc/docker/daemon.json"

export KUBE_SOURCE_REGISTRY=registry.rocketsoftware.com

export DOCKER_USERNAME=gavendano@rs.com

