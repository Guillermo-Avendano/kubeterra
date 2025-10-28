#!/bin/bash
set -Eeuo pipefail

# Set the CORE_SCRIPTS_DIR to the directory containing this script.
CORE_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"

# Source the common and registry scripts.
source "$CORE_SCRIPTS_DIR/common.sh"

get_ip() {
    # Searches for the IP of the eth0 interface or the first non-loopback IP
    # hostname -I | awk '{print $1}'
    echo localhost
}

# Usage: check_and_restart_docker
check_and_restart_docker() {
    # --- Configuration Variables ---
    DAEMON_FILE="/etc/docker/daemon.json"
    DOCKER_SERVICE="docker"

    LOCAL_IP=$(get_ip)
    local INSECURE_REGISTRY="localhost:5000"

    echo "Checking Docker daemon configuration file at: $DAEMON_FILE"

    # 1. Check if the configuration file exists
    if [ -f "$DAEMON_FILE" ]; then
        echo "✅ File $DAEMON_FILE exists. No creation needed."
    else
        echo "⚠️ File $DAEMON_FILE does not exist. Creating it with insecure registry setting."
        
        # Ensure the directory exists
        mkdir -p "$(dirname "$DAEMON_FILE")"
        
        # Create the file with the 'insecure-registries' configuration
        # This resolves the 'http: server gave HTTP response to HTTPS client' error.
        cat <<EOF | sudo tee "$DAEMON_FILE" > /dev/null
{
  "insecure-registries": [
    "$INSECURE_REGISTRY"
  ]
}
EOF
        
        echo "✅ File $DAEMON_FILE created and configured for $INSECURE_REGISTRY."
    fi

    # --- Docker Service Restart ---

    echo "Restarting the $DOCKER_SERVICE service to apply changes..."

    # Check for systemctl (common on modern Linux, like Ubuntu/WSL2)
    if command -v systemctl &> /dev/null; then
        sudo systemctl daemon-reload # Reload daemon configuration
        if sudo systemctl restart "$DOCKER_SERVICE"; then
            echo "✅ $DOCKER_SERVICE service restarted successfully."
        else
            echo "❌ ERROR: Failed to restart the $DOCKER_SERVICE service with systemctl."
            return 1
        fi
    
    # Check for 'service' command (for older systems)
    elif command-v service &> /dev/null; then
        if sudo service "$DOCKER_SERVICE" restart; then
            echo "✅ $DOCKER_SERVICE service restarted successfully."
        else
            echo "❌ ERROR: Failed to restart the $DOCKER_SERVICE service with service command."
            return 1
        fi
    else
        echo "❌ ERROR: Neither 'systemctl' nor 'service' command found. Cannot restart Docker."
        return 1
    fi

    echo "Process completed."
    return 0
}



log INFO "Installing kubectl"
curl -LO https://dl.k8s.io/release/v1.33.0/bin/linux/amd64/kubectl
sudo install kubectl /usr/local/bin/kubectl && rm kubectl

# --- Main script to install Helm ---

log INFO "Starting Helm installation process..."

# 1. Download the Helm installation script

log INFO "Downloading the 'get-helm-3' script..."
# Comprueba si get_helm.sh NO existe (-f verifica si es un archivo regular; ! niega el resultado)
if [ ! -f "get_helm.sh" ]; then
    log INFO "Script 'get_helm.sh' not found. Downloading it now..."
    
    # Intenta descargar el script
    if ! curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3; then
        log ERROR "❌ Failed to download the Helm script. Check network connectivity or the URL."
        exit 1
    fi
    
    log INFO "✅ Download complete."
else
    log INFO "Script 'get_helm.sh' already exists. Skipping download."
fi

# 2. Make the downloaded script executable
log INFO "Making the script executable..."
chmod +x get_helm.sh

# 3. Execute the script to install Helm
log INFO "Executing the Helm installation. This might require 'sudo' permissions depending on the default install path."
# The execution of the script must be checked for success ($?)
if ! ./get_helm.sh; then
    log ERROR "The Helm installation script failed during execution."
    exit 1
fi

# 4. Cleanup (optional but good practice)
log INFO "Helm installed successfully."

# Optional: Verify installation
# log INFO "Verifying Helm version..."
# helm version --short

log INFO "Installing dos2unix, net-tools, jq"
# Convert line endings for YAML, shell, and CSV files
sudo apt-get install -y dos2unix net-tools jq 


log INFO "Installing yq"
sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq 
sudo chmod +x /usr/local/bin/yq 

check_and_restart_docker;
