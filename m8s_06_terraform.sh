#!/bin/bash
set -Eeuo pipefail

# Set the CORE_SCRIPTS_DIR to the directory containing this script.
CORE_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"

TERRA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/terra/kube"

# Source the common and registry scripts.
source "$CORE_SCRIPTS_DIR/common.sh"


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
terraform init

log INFO "running : 'terraform apply -auto-approve'"
cd $TERRA_DIR

#terraform apply -auto-approve 2>&1 | tee terraform.log

export LOCAL_REGISTRY_PORT="32000"

terraform apply \
-var=var_mobiusserver_docker_artifactory_url='localhost:$LOCAL_REGISTRY_PORT/mobius-server' \
-var=var_mobiusview_docker_artifactory_url='localhost:$LOCAL_REGISTRY_PORT/mobius-view' \
-var=var_eventanalytics_docker_artifactory_url='localhost:$LOCAL_REGISTRY_PORT/eventanalytics' \
-var=var_smart_chat_docker_artifactory_url='localhost:$LOCAL_REGISTRY_PORT/smart-chat' \
-var=var_smart_chat_query_logs_docker_artifactory_url='localhost:$LOCAL_REGISTRY_PORT/smart-chat-query-logs' \
-var=var_smart_chat_indexing_proxy_docker_artifactory_url='localhost:$LOCAL_REGISTRY_PORT/smart-chat-indexing-proxy' \
-var=var_docker_username='gavendano@rs.com' \
-var=var_docker_password='Yapeyu222#' \
-var=var_docker_email='gavendano@rs.com' \
-var=var_mobius_license='01MOBIUS52464A464C4BF55859518381908FAEA4434F46515E53539681955B454D6240534556564351471D454D12405303565672514759454D1640530556560B51470E454D6040537C56560D514715454D1040536556560351470A454D0540531356560951472A454D2A40531556561D5442BBB6BC5940531A5C53A6A2B6BAB6BC5D40531A5C53A6A2B6BAB6BC2840533456561D5B42BBB6BCBBB3A23556561D5B42BBB6BCBBB3A23656563E514720454D2040535B5055F4AA8D' \
-var=var_smart_chat_openai_api_key=$OPENAI_KEY \
-var=var_pvc_storage_class='nfs-csi' | tee terraform.log
