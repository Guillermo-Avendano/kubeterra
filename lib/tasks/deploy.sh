#!/bin/bash
set -Eeuo pipefail

TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${TASK_DIR}/../.." && pwd)"
CORE_SCRIPTS_DIR="${ROOT_DIR}/lib"
TERRA_DIR="${ROOT_DIR}/terra/kube"

source "${TASK_DIR}/_env.sh"
load_env
source "${CORE_SCRIPTS_DIR}/common.sh"

log INFO "Synchronizing image versions from conf/images.csv..."
bash "${CORE_SCRIPTS_DIR}/sync_image_versions.sh"

NAMESPACE="${NAMESPACE:-mobius}"

if ! kubectl get ns "${NAMESPACE}" >/dev/null 2>&1; then
  log INFO "Creating namespace ${NAMESPACE}..."
  kubectl create ns "${NAMESPACE}"
else
  log INFO "Namespace ${NAMESPACE} already exists."
fi

helm repo add opensearch https://opensearch-project.github.io/helm-charts/ >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1 || true

cd "${TERRA_DIR}"
log INFO "Initializing Terraform..."
terraform init

if [ -d .terraform/providers/ ]; then
  chmod -R +x .terraform/providers/
fi

REQUIRED_VARS=("DOCKER_USERNAME" "DOCKER_PASSWORD" "DOCKER_EMAIL" "MOBIUS_LICENSE" "PVC_STORAGE_CLASS" "PVC_STORAGE_CAPACITY")
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var:-}" ]; then
    log ERROR "Required environment variable not set: ${var}"
    exit 1
  fi
done

log INFO "Running terraform apply..."
terraform apply \
  -var=var_namespace_mobius="${NAMESPACE}" \
  -var=var_docker_username="${DOCKER_USERNAME}" \
  -var=var_docker_password="${DOCKER_PASSWORD}" \
  -var=var_docker_email="${DOCKER_EMAIL}" \
  -var=var_mobius_license="${MOBIUS_LICENSE}" \
  -var=var_smart_chat_openai_api_key="${OPENAI_KEY:-}" \
  -var=var_pvc_storage_class="${PVC_STORAGE_CLASS}" \
  -var=var_pvc_storage_capacity="${PVC_STORAGE_CAPACITY}" \
  -var=var_mobiusserver_image="${MOBIUS_SERVER_IMAGE}" \
  -var=var_mobiusview_image="${MOBIUS_VIEW_IMAGE}" \
  -var=var_eventanalytics_image="${EVENT_ANALYTICS_IMAGE}" \
  -var=var_smart_chat_image="${SMART_CHAT_IMAGE}" \
  -var=var_smart_chat_query_logs_image="${SMART_CHAT_QUERY_LOGS_IMAGE}" \
  -var=var_smart_chat_indexing_proxy_image="${SMART_CHAT_INDEXING_PROXY_IMAGE}" \
  -var=var_appmanager_image="${APPMANAGER_IMAGE:-12.6.1}" \
  -var=var_studio_image="${STUDIO_IMAGE:-12.6.1}" \
  -var=var_processengine_image="${PROCESSENGINE_IMAGE:-12.6.1}" \
  -var=var_appmanager_docker_artifactory_url="${APPMANAGER_DOCKER_URL:-localhost:5000/appmanager}" \
  -var=var_studio_docker_artifactory_url="${STUDIO_DOCKER_URL:-localhost:5000/studio}" \
  -var=var_processengine_docker_artifactory_url="${PROCESSENGINE_DOCKER_URL:-localhost:5000/processengine}" \
  -var=var_database_appmanager_schema="${POSTGRESQL_DBNAME_APPMANAGER:-tf_mobius_am}" \
  -var=var_database_studio_schema="${POSTGRESQL_DBNAME_STUDIO:-tf_mobius_st}" \
  -var=var_database_processengine_flowable_schema="${POSTGRESQL_DBNAME_PROCESSENGINE_FLOWABLE:-tf_mobius_pe_flowable}" \
  -var=var_database_processengine_root_schema="${POSTGRESQL_DBNAME_PROCESSENGINE_ROOT:-tf_mobius_pe_root}" \
  -var=var_jwt_private_key="${MOBIUSVIEW_SECURITY_JWT_PRIVATEKEY:-}" \
  -var=var_jwt_public_key="${MOBIUSVIEW_SECURITY_JWT_PUBLICKEY:-}" \
  -var=var_process_mail_host="${PROCESS_MAIL_HOST:-}" \
  -var=var_process_mail_from_email="${PROCESS_MAIL_FROM_EMAIL_ID:-}" \
  -var=var_process_mail_username="${PROCESS_MAIL_SERVER_USERNAME:-}" \
  -var=var_process_mail_password="${PROCESS_MAIL_SERVER_PASSWORD:-}" \
  -var=var_processengine_ldap_enabled=${PROCESSENGINE_LDAP_ENABLED:-false} \
  -var=var_processengine_agent_task_enabled=${AGENT_TASK_ENABLED:-false} \
  -var=var_processengine_openai_api_key="${OPENAI_API_KEY:-}" \
  -var=var_mcp_server_name="${MCP_SERVER_NAME:-}" \
  -var=var_mcp_server_url="${MCP_SERVER_URL:-}" \
  -var=var_mcp_server_path="${MCP_SERVER_PATH:-}" \
  -var=var_studio_template_display_name="${OPTIONAL_DISPLAY_TEMPLATE_NAME:-Default Template}" \
  -var=var_studio_template_local_path="${MANDATORY_TEMPLATE_PATH:-/home/asg/templates/default.proj}" \
  -var=var_ingress_hostname="${HOSTNAME:-localhost}" \
  -auto-approve 2>&1 | tee terraform.log

log INFO "Terraform deployment completed."
