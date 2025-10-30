#!/bin/bash
set -Eeuo pipefail

# Set the CORE_SCRIPTS_DIR to the directory containing this script.
CORE_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"


# Source the common and registry scripts.
source "$CORE_SCRIPTS_DIR/common.sh"
source "$CORE_SCRIPTS_DIR/env.sh"

log INFO "======================================="
log INFO "Variables from $CORE_SCRIPTS_DIR/env.sh"
log INFO "======================================="
./tools.sh pull