#!/bin/bash
set -Eeuo pipefail

# Set the CORE_SCRIPTS_DIR to the directory containing this script.
CORE_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"

# Source the common and registry scripts.
source "$CORE_SCRIPTS_DIR/common.sh"


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

