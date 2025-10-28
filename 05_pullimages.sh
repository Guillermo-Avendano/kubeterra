#!/bin/bash
set -Eeuo pipefail

# Set the CORE_SCRIPTS_DIR to the directory containing this script.
CORE_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"

export KUBE_SOURCE_REGISTRY=registry.rocketsoftware.com


# Source the common and registry scripts.
source "$CORE_SCRIPTS_DIR/common.sh"

log INFO "Configure & run: 'source ./env_kubelocal.sh'"

./tools.sh pull