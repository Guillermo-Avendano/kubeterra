#!/bin/bash
set -Eeuo pipefail

# Set the CORE_SCRIPTS_DIR to the directory containing this script.
CORE_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"

# Source the common and registry scripts.
source "$CORE_SCRIPTS_DIR/common.sh"

log INFO "Installing dos2unix, net-tools, jq"
# Convert line endings for YAML, shell, and CSV files
sudo apt-get install -y dos2unix net-tools jq 


log INFO "Installing yq"
sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq 
sudo chmod +x /usr/local/bin/yq 

