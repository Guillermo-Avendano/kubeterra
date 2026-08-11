#!/bin/bash
set -Eeuo pipefail

TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${TASK_DIR}/../.." && pwd)"
CORE_SCRIPTS_DIR="${ROOT_DIR}/lib"

source "${CORE_SCRIPTS_DIR}/common.sh"

load_env() {
  local env_file="${ROOT_DIR}/.env"
  if [ ! -f "${env_file}" ]; then
    log ERROR ".env not found at ${env_file}. Copy .env.example to .env and configure it."
    exit 1
  fi

  set -a
  source "${env_file}"
  set +a

  export ROOT_DIR CORE_SCRIPTS_DIR
}
