#!/bin/bash

source "$CORE_SCRIPTS_DIR/common.sh"

export KUBE_SOURCE_REGISTRY=registry.rocketsoftware.com

get_ip() {
    # Searches for the IP of the eth0 interface or the first non-loopback IP
    # hostname -I | awk '{print $1}'
    echo localhost
}

env_images() {

    IMAGES_FILE="$CORE_DIR/conf/images.csv"
    highlight_message "Using default file: $IMAGES_FILE"

    if [[ ! -f "$IMAGES_FILE" ]]; then
        log ERROR "File not found: $IMAGES_FILE"
        exit 1
    fi

}

# Usage: check_and_restart_docker
check_and_restart_docker() {
    # --- Configuration Variables ---
    DAEMON_FILE="/etc/docker/daemon.json"
    DOCKER_SERVICE="docker"

    LOCAL_IP=$(get_ip)
    local INSECURE_REGISTRY="localhost:5000"

    echo "Checking Docker daemon configuration file at: $DAEMON_FILE"

    # 1. Check if the configuration file exists
    if [ -f "$DAEMON_FILE" ]; then
        echo "✅ File $DAEMON_FILE exists. No creation needed."
    else
        echo "⚠️ File $DAEMON_FILE does not exist. Creating it with insecure registry setting."
        
        # Ensure the directory exists
        mkdir -p "$(dirname "$DAEMON_FILE")"
        
        # Create the file with the 'insecure-registries' configuration
        # This resolves the 'http: server gave HTTP response to HTTPS client' error.
        cat <<EOF | sudo tee "$DAEMON_FILE" > /dev/null
{
  "insecure-registries": [
    "$INSECURE_REGISTRY"
  ]
}
EOF
        
        echo "✅ File $DAEMON_FILE created and configured for $INSECURE_REGISTRY."
    fi

    # --- Docker Service Restart ---

    echo "Restarting the $DOCKER_SERVICE service to apply changes..."

    # Check for systemctl (common on modern Linux, like Ubuntu/WSL2)
    if command -v systemctl &> /dev/null; then
        sudo systemctl daemon-reload # Reload daemon configuration
        if sudo systemctl restart "$DOCKER_SERVICE"; then
            echo "✅ $DOCKER_SERVICE service restarted successfully."
        else
            echo "❌ ERROR: Failed to restart the $DOCKER_SERVICE service with systemctl."
            return 1
        fi
    
    # Check for 'service' command (for older systems)
    elif command-v service &> /dev/null; then
        if sudo service "$DOCKER_SERVICE" restart; then
            echo "✅ $DOCKER_SERVICE service restarted successfully."
        else
            echo "❌ ERROR: Failed to restart the $DOCKER_SERVICE service with service command."
            return 1
        fi
    else
        echo "❌ ERROR: Neither 'systemctl' nor 'service' command found. Cannot restart Docker."
        return 1
    fi

    echo "Process completed."
    return 0
}

# Usage: pull_images
pull_images() {
    local registry_src="$KUBE_SOURCE_REGISTRY"

    log "INFO" "Pulling images from $registry_src using $CORE_DIR/conf/images.csv"
    read -s -p "Docker password for $DOCKER_USERNAME : " DOCKER_PASSWORD
    echo ""

    if ! docker login --username "$DOCKER_USERNAME" --password "$DOCKER_PASSWORD" "$registry_src"; then
        log "ERROR" "Failed to login to $registry_src"
        exit 1
    fi

    env_images
    while IFS=: read -r image_name image_tag; do
        # Skip empty lines or comments
        if [[ "$image_name" == \#* ]] || [[ -z "$image_name" ]]; then
            continue
        fi

        log "PROGRESS" "Pulling $registry_src/$image_name:$image_tag \n"
        if ! docker pull "$registry_src/$image_name:$image_tag"; then
            log "ERROR" "Failed to pull $image_name:$image_tag"
            exit 1
        fi
    done < "$IMAGES_FILE"
}

tag_images() {
    local registry_src="$KUBE_SOURCE_REGISTRY"

    LOCAL_IP=$(get_ip)
    local registry_target="${LOCAL_IP}:5000"

    log "INFO" "Tagging images from $registry_src to $registry_target"
    env_images
    while IFS=: read -r image_name image_tag; do
        # Skip empty lines or comments
        if [[ "$image_name" == \#* ]] || [[ -z "$image_name" ]]; then
            continue
        fi

        log "PROGRESS" "Tagging $registry_src/$image_name:$image_tag to $registry_target/$image_name:$image_tag \n"
        if ! docker tag "$registry_src/$image_name:$image_tag" "$registry_target/$image_name:$image_tag"; then
            log "ERROR" "Failed to tag $image_name:$image_tag"
            exit 1
        fi
    done < "$IMAGES_FILE"
}

list_images() {
    local registry_src="$KUBE_SOURCE_REGISTRY"

    log "INFO" "Listing images from $registry_src using $CORE_DIR/conf/images.csv"
    read -s -p "Docker password for $DOCKER_USERNAME : " DOCKER_PASSWORD
    echo ""

    env_images
    while IFS=: read -r image_name image_tag; do
        # Skip empty lines or comments
        if [[ "$image_name" == \#* ]] || [[ -z "$image_name" ]]; then
            continue
        fi
        log "PROGRESS" "Fetching tags for $image_name \n"
        # Obtener el JSON de los tags
        response=$(curl -s -X GET -u "$DOCKER_USERNAME:$DOCKER_PASSWORD" "https://$registry_src/v2/$image_name/tags/list")
        if [[ $? -ne 0 ]]; then
            log "ERROR" "Failed to list tags for $image_name"
            exit 1
        fi

        # Extraer los tags, ordenarlos y unirlos en una sola línea con comas
        tags=$(echo "$response" | jq -r '.tags[]' | sort -V -r | tr '\n' ',' | sed 's/,$//')

        # Imprimir los tags en una sola línea
        
        log "INFO" "Tags for $image_name (sorted highest to lowest):"
        echo "$tags"

        echo ""
    done < "$IMAGES_FILE"
}



list_images_local() {
    
    LOCAL_IP=$(get_ip)
    local registry_target="${LOCAL_IP}:5000"

    log "INFO" "Listing local images from $registry_target"
    env_images
    while IFS=: read -r image_name image_tag; do
        # Skip empty lines or comments
        if [[ "$image_name" == \#* ]] || [[ -z "$image_name" ]]; then
            continue
        fi
        log "PROGRESS" "Fetching tags for $image_name in $registry_target \n"
        if ! curl -s -X GET "http://$registry_target/v2/$image_name/tags/list"; then
            log "ERROR" "Failed to list tags for $image_name in $registry_target"
            exit 1
        fi
        echo ""
    done < "$IMAGES_FILE"
}

push_images() {

    env_images;

    check_and_restart_docker;

    LOCAL_IP=$(get_ip)
    local registry_target="${LOCAL_IP}:5000"

    log "INFO" "Logging into local registry $registry_target"

    DOCKER_PASSWORD_LOCAL=test
    DOCKER_USER_LOCAL=test

    if ! echo "$DOCKER_PASSWORD_LOCAL" | docker login --username "$DOCKER_USER_LOCAL" --password-stdin "$registry_target"; then
        log "ERROR" "Failed to login to $registry_target"
        exit 1
    fi

    while IFS=: read -r image_name image_tag; do
        # Skip empty lines or comments
        if [[ "$image_name" == \#* ]] || [[ -z "$image_name" ]]; then
            continue
        fi

        log "PROGRESS" "Pushing $registry_target/$image_name:$image_tag \n"
        if ! docker push "$registry_target/$image_name:$image_tag"; then
            log "ERROR" "Failed to push $image_name:$image_tag"
            exit 1
        fi
    done < "$IMAGES_FILE"
}

push_images_to_local_registry() {

    log "INFO" "Starting image pull"
    pull_images

    log "INFO" "Starting image tagging"
    tag_images

    log "INFO" "Starting image push to local registry"
    push_images
}