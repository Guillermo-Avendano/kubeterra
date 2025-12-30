#!/bin/bash
set -Eeuo pipefail

# Set the CORE_SCRIPTS_DIR to the directory containing this script.
CORE_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"

TERRA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/terra/kube"

# Source the common and registry scripts.
source "$CORE_SCRIPTS_DIR/common.sh"

# Synchronize image versions from conf/images.csv to .env files
log INFO "Synchronizing image versions from conf/images.csv..."
if [ -f "$CORE_SCRIPTS_DIR/sync_image_versions.sh" ]; then
    bash "$CORE_SCRIPTS_DIR/sync_image_versions.sh"
else
    log WARN "sync_image_versions.sh not found. Skipping image version synchronization."
fi

# Load environment variables from .env.local
if [ -f ".env.local" ]; then
    source ".env.local"
    log INFO "Loaded environment variables from .env.local"
else
    log ERROR ".env.local not found. Please copy .env.example to .env.local and configure it."
    exit 1
fi


NAMESPACE=mobius

if ! kubectl get ns "$NAMESPACE" &> /dev/null; then
    
    # Se o kubectl get ns falhar (código de saída != 0), o namespace não existe.
    echo "[INFO] Creating namespace $NAMESPACE..."
    kubectl create ns "$NAMESPACE"
    
else
    # Se o kubectl get ns for bem-sucedido (código de saída == 0), o namespace já existe.
    echo "[INFO] Namespace $NAMESPACE already exists. Skipping creation."
fi

helm repo add opensearch https://opensearch-project.github.io/helm-charts/;
helm repo update;

cd terra/kube
log INFO "Initializing Terraform..."

# Run init to download providers; chmod only if directory exists
terraform init

if [ -d .terraform/providers/ ]; then
    chmod -R +x .terraform/providers/
fi

log INFO "running : 'terraform apply'"
cd $TERRA_DIR

# Verify required environment variables
REQUIRED_VARS=("DOCKER_USERNAME" "DOCKER_PASSWORD" "DOCKER_EMAIL" "MOBIUS_LICENSE" "PVC_STORAGE_CLASS" "PVC_STORAGE_CAPACITY")
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
        log ERROR "Required environment variable not set: $var"
        log ERROR "Please source .env.local or set the variable manually"
        exit 1
    fi
done

log INFO "Deploying with environment variables..."
log INFO "  Namespace: ${NAMESPACE}"
log INFO "  Docker Registry: ${DOCKER_REGISTRY:-registry.rocketsoftware.com}"
log INFO "  PVC Storage Class: ${PVC_STORAGE_CLASS}"
log INFO "  PVC Storage Capacity: ${PVC_STORAGE_CAPACITY}"
log INFO "  Image Versions:"
log INFO "    - Mobius Server: ${MOBIUS_SERVER_IMAGE}"
log INFO "    - Mobius View: ${MOBIUS_VIEW_IMAGE}"
log INFO "    - Event Analytics: ${EVENT_ANALYTICS_IMAGE}"
log INFO "    - Smart Chat: ${SMART_CHAT_IMAGE}"

terraform apply \
  -var=var_namespace_mobius="${NAMESPACE:-mobius}" \
  -var=var_docker_username="${DOCKER_USERNAME}" \
  -var=var_docker_password="${DOCKER_PASSWORD}" \
  -var=var_docker_email="${DOCKER_EMAIL}" \
  -var=var_mobius_license="${MOBIUS_LICENSE}" \
  -var=var_smart_chat_openai_api_key="${OPENAI_KEY}" \
  -var=var_pvc_storage_class="${PVC_STORAGE_CLASS}" \
  -var=var_pvc_storage_capacity="${PVC_STORAGE_CAPACITY}" \
  -var=var_mobiusserver_image="${MOBIUS_SERVER_IMAGE}" \
  -var=var_mobiusview_image="${MOBIUS_VIEW_IMAGE}" \
  -var=var_eventanalytics_image="${EVENT_ANALYTICS_IMAGE}" \
  -var=var_smart_chat_image="${SMART_CHAT_IMAGE}" \
  -var=var_smart_chat_query_logs_image="${SMART_CHAT_QUERY_LOGS_IMAGE}" \
  -var=var_smart_chat_indexing_proxy_image="${SMART_CHAT_INDEXING_PROXY_IMAGE}" \
  -auto-approve 2>&1 | tee terraform.log

if [ $? -eq 0 ]; then
    log INFO "Terraform deployment completed successfully"
else
    log ERROR "Terraform deployment failed. Check terraform.log for details"
    exit 1
fi

log INFO "Terraform apply completed."