#!/bin/bash
set -Eeuo pipefail

TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${TASK_DIR}/../.." && pwd)"

source "${TASK_DIR}/_env.sh"
load_env

action="${1:-pull}"

cd "${ROOT_DIR}"
case "${action}" in
  pull|tag|push|ptp|remote|local|nfs|debug|ingress|nginx|clean)
    ./tools.sh "${action}"
    ;;
  *)
    echo "Unknown images action: ${action}"
    echo "Valid actions: pull, tag, push, ptp, remote, local, nfs, debug, ingress, nginx, clean"
    exit 1
    ;;
esac
