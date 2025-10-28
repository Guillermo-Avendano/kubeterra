#!/bin/bash
# Set the CORE_SCRIPTS_DIR to the directory containing this script.
CORE_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"

# Source the common and registry scripts.
source "$CORE_SCRIPTS_DIR/common.sh"

log INFO "Do the changes in 'env_kubelocal.sh' and execute:"
log INFO "source ./env_kubelocal.sh"
log INFO "before ./05_pullimages.sh"
