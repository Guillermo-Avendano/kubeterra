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

terraform apply -auto-approve