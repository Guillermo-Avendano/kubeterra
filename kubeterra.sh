#!/bin/bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_SCRIPTS_DIR="${ROOT_DIR}/lib"

source "${CORE_SCRIPTS_DIR}/common.sh"

usage() {
  cat <<'EOF'
Usage: ./kubeterra.sh <command> [args]

Commands:
  prereqs            Install host prerequisites (Docker, kubectl, Helm, jq, yq)
  cluster            Bootstrap cluster: MicroK8s+NFS+registry on Ubuntu, K3s/Rancher/NFS/registry elsewhere
  images [action]    Manage images via tools.sh (default action: pull)
  deploy             Run Terraform deployment
  doctor             Validate local environment and required variables
  all                Run prereqs -> cluster -> images pull -> deploy
  sync-images        Sync image versions from conf/images.csv to .env/.env.example
  help               Show this help
EOF
}

run_task() {
  local task="$1"
  shift || true
  bash "${ROOT_DIR}/lib/tasks/${task}.sh" "$@"
}

main() {
  local cmd="${1:-help}"

  case "$cmd" in
    prereqs)
      run_task prereqs
      ;;
    cluster)
      run_task cluster
      ;;
    images)
      shift || true
      run_task images "$@"
      ;;
    deploy)
      run_task deploy
      ;;
    doctor)
      run_task doctor
      ;;
    all)
      run_task prereqs
      run_task cluster
      run_task images pull
      run_task deploy
      ;;
    sync-images)
      bash "${ROOT_DIR}/lib/sync_image_versions.sh"
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      log ERROR "Unknown command: ${cmd}"
      usage
      exit 1
      ;;
  esac
}

main "$@"
