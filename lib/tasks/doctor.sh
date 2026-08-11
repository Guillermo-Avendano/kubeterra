#!/bin/bash
set -Eeuo pipefail

TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${TASK_DIR}/../.." && pwd)"

source "${TASK_DIR}/_env.sh"
load_env

missing=0
for cmd in bash curl docker kubectl helm terraform jq yq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[MISSING] $cmd"
    missing=1
  else
    echo "[OK] $cmd"
  fi
done

required_vars=(DOCKER_USERNAME DOCKER_PASSWORD DOCKER_EMAIL MOBIUS_LICENSE PVC_STORAGE_CLASS PVC_STORAGE_CAPACITY)
for var in "${required_vars[@]}"; do
  if [ -z "${!var:-}" ]; then
    echo "[MISSING VAR] $var"
    missing=1
  else
    echo "[OK VAR] $var"
  fi
done

if [ "$missing" -ne 0 ]; then
  echo "Doctor checks failed."
  exit 1
fi

echo "Doctor checks passed."
