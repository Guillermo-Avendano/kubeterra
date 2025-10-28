#!/bin/bash
# ingress.sh: Manages NGINX ingress controller and ingress resources
# Usage: source ingress.sh; install_nginx | install_ingress | remove_nginx | update_nginx | install_ingress_extra <ingress_id>
# Requires: helm, kubectl, yq, ROOT_DIR, NAMESPACE, MYDEBUG

set -Eeuo pipefail

source "${CORE_SCRIPTS_DIR:-.}/common.sh"
source "${CORE_SCRIPTS_DIR:-.}/certificates.sh"

# Function to log messages
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    case "$level" in
        INFO)  color="\033[1;32m" ;; # Green
        ERROR) color="\033[1;31m" ;; # Red
        WARN)  color="\033[1;33m" ;; # Yellow
        *)     color="\033[0m"    ;; # No color
    esac
    echo -e "${color}${timestamp} [$level] ${message}\033[0m" >&2
}

# Function to initialize NGINX environment
setup_nginx_env() {

    if [[ -n "${INGRESS_FILENAME:-}" ]]; then
        INGRESS_FILE="$CORE_DIR/conf/$INGRESS_FILENAME"
        highlight_message "Using INGRESS_FILENAME: $INGRESS_FILE"
    else
        INGRESS_FILE="$CORE_DIR/conf/ingress.csv"
        highlight_message "Using default file: $INGRESS_FILE"
    fi

    if [[ ! -f "$INGRESS_FILE" ]]; then
        log ERROR "File not found: $INGRESS_FILE"
        exit 1
    fi

    NGINX_NAMESPACE="ingress-nginx"
    INGRESS_TEMPLATES_DIR="$CORE_DIR/templates/ingress"
    INGRESS_DEPLOY_DIR="$CORE_DIR/deploy"

    # Create namespace if it doesn't exist
    if [ "${MYDEBUG:-false}" != "true" ]; then
        if ! kubectl get namespace "$NGINX_NAMESPACE" &>/dev/null; then
            log INFO "Creating namespace $NGINX_NAMESPACE..."
            kubectl create namespace "$NGINX_NAMESPACE" || {
                log ERROR "Failed to create namespace $NGINX_NAMESPACE."
                exit 1
            }
        fi
    fi

    # Validate directories and files
    for dir in "$INGRESS_TEMPLATES_DIR" "$INGRESS_DEPLOY_DIR"; do
        if [ ! -d "$dir" ]; then
            log ERROR "Directory $dir does not exist."
            exit 1
        fi
    done
    for file in "$INGRESS_FILE" ; do
        if [ ! -f "$file" ]; then
            log ERROR "File $file does not exist."
            exit 1
        fi
    done

    export NGINX_NAMESPACE INGRESS_TEMPLATES_DIR INGRESS_FILE INGRESS_DEPLOY_DIR
}

# Function to create an ingress resource
create_ingress() {
    local ingress_template="$1"
    local host="$2"
    local namespace="$3"
    local deploy_dir="$4"

    local secret_name
    secret_name=$(echo "$host" | sed -r 's#\.#-#g')
    local ingress_file="$deploy_dir/${namespace}_${secret_name}_${ingress_template}"
    local template_file="$INGRESS_TEMPLATES_DIR/$ingress_template"

    # Validate template
    if [ ! -f "$template_file" ]; then
        log ERROR "Template $template_file does not exist."
        exit 1
    fi

    # Create secret
    create_secret "$host" "$deploy_dir" "$namespace"

    # Generate ingress YAML
    log INFO "Generating ingress for $host..."
    cp "$template_file" "$ingress_file" || {
        log ERROR "Failed to copy template $template_file to $ingress_file."
        exit 1
    }

    yq eval -i "
        .metadata.name = \"$secret_name\" |
        .spec.tls[0].hosts[0] = \"$host\" |
        .spec.tls[0].secretName = \"$secret_name\" |
        .spec.rules[0].host = \"$host\"
        " "$ingress_file" || {
        log ERROR "Failed to update ingress YAML $ingress_file."
        exit 1
    }

    # Apply ingress
    if [ "${MYDEBUG:-false}" == "true" ]; then
        echo "kubectl apply -f $ingress_file --namespace $namespace"
    else
        kubectl apply -f "$ingress_file" --namespace "$namespace" || {
            log ERROR "Failed to apply ingress $ingress_file."
            exit 1
        }
        log INFO "Ingress $secret_name applied successfully."
    fi
}

# Function to install ingress resources from CSV
install_ingress() {

    p_namespace=${1:-""}

    setup_nginx_env

    log INFO "Installing ingress resources from $INGRESS_FILE..."
    #echo "# "Creating ingress resources from $INGRESS_FILE..."" > $DEPLOY_SCRIPT

    while IFS=, read -r ingress_template host namespace; do
        # Skip comments and empty lines
        if [[ "$ingress_template" == \#* ]] || [[ -z "$ingress_template" ]]; then
            continue
        fi

        # Use default namespace if not specified
        namespace="${namespace:-$NAMESPACE}"

        if [ -n "$p_namespace" ]; then
            if [ "$p_namespace" != "$namespace" ]; then
                continue
            fi
        fi    

        # Validate namespace
        if ! kubectl get namespace "$namespace" &>/dev/null; then
            log WARN "Namespace $namespace does not exist. The ingress template: $ingress_template, with host: $host won't be defined."
        else
            create_ingress "$ingress_template" "$host" "$namespace" "$INGRESS_DEPLOY_DIR"
            log INFO "----------------------------------------------------------------"
            sleep 2
        fi


    done < "$INGRESS_FILE"
}

# Function to install NGINX ingress controller
install_nginx() {

    setup_nginx_env

    log INFO "Installing NGINX ingress controller version ${NGINX_VERSION:-latest}..."

    if [ "${MYDEBUG:-false}" == "true" ]; then
        echo "helm install nginx ingress-nginx/ingress-nginx -n $NGINX_NAMESPACE"
    else
        helm install nginx ingress-nginx/ingress-nginx -n "$NGINX_NAMESPACE" || {
            log ERROR "Failed to install NGINX ingress controller."
            exit 1
        }
        log INFO "Waiting for NGINX to be ready..."
        sleep 30
    fi
}

# Function to remove NGINX ingress controller and resources
remove_nginx() {
    setup_nginx_env

    log INFO "Removing NGINX ingress controller and resources..."

    # Delete ingress resources
    local ingresses
    ingresses=$(kubectl get ingress -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
    if [ -n "$ingresses" ]; then
        kubectl delete ingress -n "$NAMESPACE" $ingresses || {
            log WARN "Failed to delete some ingress resources."
        }
    fi

    # Delete TLS secrets
    local secrets
    secrets=$(kubectl get secret -n "$NAMESPACE" --field-selector type=kubernetes.io/tls -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
    if [ -n "$secrets" ]; then
        kubectl delete secret -n "$NAMESPACE" $secrets || {
            log WARN "Failed to delete some TLS secrets."
        }
    fi

    # Uninstall NGINX Helm chart
    if [ "${MYDEBUG:-false}" == "true" ]; then
        echo "helm uninstall nginx -n $NGINX_NAMESPACE"
    else
        helm uninstall nginx -n "$NGINX_NAMESPACE" || {
            log WARN "Failed to uninstall NGINX Helm chart."
        }
    fi

    # Delete namespace
    if [ "${MYDEBUG:-false}" == "true" ]; then
        echo "kubectl delete namespace $NGINX_NAMESPACE"
    else
        kubectl delete namespace "$NGINX_NAMESPACE" || {
            log WARN "Failed to delete namespace $NGINX_NAMESPACE."
        }
    fi

    log INFO "Waiting for NGINX resources to be removed..."
    sleep 10
}

# Function to update NGINX ingress controller
update_nginx() {
    setup_nginx_env

    log INFO "Updating NGINX ingress controller version ${NGINX_VERSION:-latest}..."

    # Delete existing ingress resources
    local ingresses
    ingresses=$(kubectl get ingress -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
    if [ -n "$ingresses" ]; then
        kubectl delete ingress -n "$NAMESPACE" $ingresses || {
            log WARN "Failed to delete some ingress resources."
        }
    fi

    # Delete existing TLS secrets
    local secrets
    secrets=$(kubectl get secret -n "$NAMESPACE" --field-selector type=kubernetes.io/tls -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
    if [ -n "$secrets" ]; then
        kubectl delete secret -n "$NAMESPACE" $secrets || {
            log WARN "Failed to delete some TLS secrets."
        }
    fi

    # Check if the release exists
    if helm status nginx -n "$NGINX_NAMESPACE" &>/dev/null; then
        # Upgrade if exists
        if [ "${MYDEBUG:-false}" == "true" ]; then
            echo "helm upgrade nginx ingress-nginx/ingress-nginx -n $NGINX_NAMESPACE"
        else
            helm upgrade nginx ingress-nginx/ingress-nginx -n "$NGINX_NAMESPACE" || {
                log ERROR "Failed to upgrade NGINX ingress controller."
                exit 1
            }
        fi
    else
        # Install if not exists
        if [ "${MYDEBUG:-false}" == "true" ]; then
            echo "helm install nginx ingress-nginx/ingress-nginx -n $NGINX_NAMESPACE"
        else
            helm install nginx ingress-nginx/ingress-nginx -n "$NGINX_NAMESPACE" || {
                log ERROR "Failed to install NGINX ingress controller."
                exit 1
            }
        fi
    fi

    log INFO "Waiting for NGINX to be ready..."
    kubectl wait --for=condition=Ready pod --all -n "$NGINX_NAMESPACE" --timeout=300s || {
        log WARN "NGINX pods did not become ready within 300 seconds."
    }
}