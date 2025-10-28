#!/bin/bash
# certificates.sh: Generates root and site certificates, and creates Kubernetes TLS secrets
# Usage: source certificates.sh; generate_certificate <host> <secret_name> <deploy_dir> [namespace]
# Requires: openssl, kubectl, CORE_SCRIPTS_DIR, NAMESPACE, MYDEBUG

set -Eeuo pipefail

source "$CORE_SCRIPTS_DIR/common.sh"
source "$CORE_DIR/conf/env.sh"

# Function to set up certificate directories
setup_cert_directories() {
    CERT_DIRECTORY="${CORE_SCRIPTS_DIR}/cert"
    CA_DIRECTORY="${CORE_SCRIPTS_DIR}/cert/ca"

    for dir in "$CERT_DIRECTORY" "$CA_DIRECTORY"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir" || {
                log ERROR "Failed to create directory $dir."
                exit 1
            }
            log INFO "Created directory $dir."
        fi
    done

    export CERT_DIRECTORY CA_DIRECTORY
}

# Function to generate root certificate
generate_root_certificate() {
    setup_cert_directories

    local ca_key="$CA_DIRECTORY/ca.key"
    local ca_crt="$CA_DIRECTORY/ca.crt"
    local ca_csr="$CA_DIRECTORY/ca.csr"
    local ca_config="$CA_DIRECTORY/ca.cnf"

    # Skip if root certificate already exists
    if [ -f "$ca_key" ] && [ -f "$ca_crt" ] && [ -f "$ca_csr" ]; then
        log INFO "Root certificate already exists, skipping generation."
        return 0
    fi

    log INFO "Generating root certificate..."

    # Generate private key
    openssl genrsa -out "$ca_key" 4096 || {
        log ERROR "Failed to generate CA private key."
        exit 1
    }

    # Create CA configuration
    cat > "$ca_config" << EOF
[req]
default_bits = 4096
prompt = no
distinguished_name = ca_dn
[ca_dn]
C = AR
ST = Buenos Aires
L = La Plata
O = Rocket Software
OU = Sales Engineering
CN = Rocket Software ROOT Certificate
[req_ext]
subjectAltName = @alt_names
[alt_names]
DNS.1 = localhost
IP.1 = 127.0.0.1
EOF

    # Generate CSR
    openssl req -new -config "$ca_config" -key "$ca_key" -out "$ca_csr" || {
        log ERROR "Failed to generate CA CSR."
        exit 1
    }

    # Generate self-signed certificate
    openssl x509 -req -in "$ca_csr" -signkey "$ca_key" -out "$ca_crt" -days 3650 || {
        log ERROR "Failed to generate CA certificate."
        exit 1
    }

    log INFO "Root certificate generated successfully."
}

# Function to verify if a certificate is signed by the CA
verify_certificate() {
    local host="$1"
    log INFO "Verifying certificate $host.crt..."
    log INFO "------------------------------------------------"
    log INFO "openssl verify -CAfile $CA_DIRECTORY/ca.crt $CERT_DIRECTORY/$host.crt"
    log INFO "------------------------------------------------"

    if openssl verify -CAfile "$CA_DIRECTORY/ca.crt" "$CERT_DIRECTORY/$host.crt"; then
        log INFO "Certificate $host.crt is correctly signed by ca.crt."
    else
        log ERROR "Certificate $host.crt is NOT signed by ca.crt."
    fi
}

# Function to generate site certificate and Kubernetes secret
generate_certificate() {
    local host="$1"
    local secret_name="$2"
    local deploy_dir="$3"
    local namespace="${4:-$NAMESPACE}"

    # Validate inputs
    if [ -z "$host" ] || [ -z "$secret_name" ] || [ -z "$deploy_dir" ] || [ -z "$namespace" ]; then
        log ERROR "Missing required arguments: host, secret_name, deploy_dir, or namespace."
        exit 1
    fi

    setup_cert_directories

    # Generate root certificate if missing
    generate_root_certificate

    local secret_file="$deploy_dir/$host-secrets.yaml"
    if [ ! -d "$deploy_dir" ]; then
        log WARN "Deploy directory $deploy_dir does not exist, using $CERT_DIRECTORY."
        secret_file="$CERT_DIRECTORY/$host-secrets.yaml"
        mkdir -p "$CERT_DIRECTORY" || {
            log ERROR "Failed to create directory $CERT_DIRECTORY."
            exit 1
        }
    fi

    log INFO "Generating certificate for $host..."

    # Generate private key
    openssl genrsa -out "$CERT_DIRECTORY/$host.key" 2048 || {
        log ERROR "Failed to generate private key for $host."
        exit 1
    }

    # Generate CSR
    openssl req -new -key "$CERT_DIRECTORY/$host.key" \
                -out "$CERT_DIRECTORY/$host.csr" \
                -subj "/CN=$host" || {
        log ERROR "Failed to generate CSR for $host."
        exit 1
    }

    # Create extension file
    echo "subjectAltName=DNS:$host" > "$CERT_DIRECTORY/$host.ext"

    # Sign certificate
    openssl x509 -req -in "$CERT_DIRECTORY/$host.csr" \
                 -out "$CERT_DIRECTORY/$host.crt" \
                 -CA "$CA_DIRECTORY/ca.crt" \
                 -CAkey "$CA_DIRECTORY/ca.key" \
                 -CAcreateserial \
                 -days 3650 \
                 -sha256 \
                 -extfile "$CERT_DIRECTORY/$host.ext" || {
        log ERROR "Failed to sign certificate for $host."
        exit 1
    }

    # Verify certificate signature
    verify_certificate "$host"

    # Create Kubernetes secret
    kubectl -n "$namespace" create secret tls "$secret_name" \
            --key "$CERT_DIRECTORY/$host.key" \
            --cert "$CERT_DIRECTORY/$host.crt" \
            --dry-run=client -o yaml > "$secret_file" || {
        log ERROR "Failed to create secret YAML for $secret_name."
        exit 1
    }

    log INFO "Certificate and secret YAML generated for $host at $secret_file."
}

# Function to create or update a Kubernetes secret
create_secret() {
    local host="$1"
    local deploy_dir="$2"
    local namespace="${3:-$NAMESPACE}"

    # Validate inputs
    if [ -z "$host" ] || [ -z "$deploy_dir" ] || [ -z "$namespace" ]; then
        log ERROR "Missing required arguments: host, deploy_dir, or namespace."
        exit 1
    fi

    local secret_name
    secret_name=$(echo "$host" | sed -E 's#\.#-#g')

    # Check if namespace exists
    if ! kubectl get namespace "$namespace" &>/dev/null; then
        log ERROR "Namespace $namespace does not exist."
        exit 1
    fi

    # Delete existing secret if it exists
    if kubectl -n "$namespace" get secret "$secret_name" -o name &>/dev/null; then
        log INFO "Deleting existing secret $secret_name..."
        if [ "${MYDEBUG:-false}" == "true" ]; then
            log INFO "kubectl --namespace $namespace delete secret $secret_name"
        else
            kubectl -n "$namespace" delete secret "$secret_name" || {
                log ERROR "Failed to delete secret $secret_name."
                exit 1
            }
        fi
    fi

    # Generate certificate and secret
    log INFO "Creating secret $secret_name..."
    generate_certificate "$host" "$secret_name" "$deploy_dir" "$namespace"

    # Apply secret
    if [ "${MYDEBUG:-false}" == "true" ]; then
        log INFO "kubectl --namespace $namespace apply -f $deploy_dir/$host-secrets.yaml"
    else
        kubectl -n "$namespace" apply -f "$deploy_dir/$host-secrets.yaml" || {
            log ERROR "Failed to apply secret $deploy_dir/$host-secrets.yaml."
            exit 1
        }
        log INFO "Secret $secret_name applied successfully."
    fi
}