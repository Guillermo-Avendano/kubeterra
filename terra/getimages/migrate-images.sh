#!/bin/bash
# migrate-images.sh
# This script pulls Docker images from a source registry and pushes them to a target registry

set -e

# Configuration
SOURCE_REGISTRY="${1:-registry.rocketsoftware.com}"
TARGET_REGISTRY="${2:-localhost:5000}"
SOURCE_USERNAME="${3:-}"
SOURCE_PASSWORD="${4:-}"
IMAGES_CSV="${5:-../conf/images.csv}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to authenticate with source registry
docker_login() {
    if [ -z "$SOURCE_USERNAME" ] || [ -z "$SOURCE_PASSWORD" ]; then
        log_warn "No credentials provided for source registry. Assuming you're already logged in."
        return 0
    fi
    
    log_info "Authenticating with $SOURCE_REGISTRY..."
    echo "$SOURCE_PASSWORD" | docker login -u "$SOURCE_USERNAME" --password-stdin "$SOURCE_REGISTRY" || {
        log_error "Failed to authenticate with $SOURCE_REGISTRY"
        log_error "Check your credentials and try again"
        return 1
    }
    log_info "Successfully authenticated with $SOURCE_REGISTRY"
}

# Function to read images from CSV
read_images() {
    if [ ! -f "$IMAGES_CSV" ]; then
        log_error "CSV file not found: $IMAGES_CSV"
        return 1
    fi
    
    # Skip header and extract image names
    tail -n +2 "$IMAGES_CSV" | cut -d',' -f1 | grep -v '^$'
}

# Function to pull image
pull_image() {
    local image=$1
    local source_image="${SOURCE_REGISTRY}/${image}"
    
    log_info "Pulling $source_image..."
    if docker pull "$source_image"; then
        log_info "Successfully pulled $source_image"
        return 0
    else
        log_error "Failed to pull $source_image"
        return 1
    fi
}

# Function to tag and push image
tag_and_push() {
    local image=$1
    local source_image="${SOURCE_REGISTRY}/${image}"
    local target_image="${TARGET_REGISTRY}/${image}"
    
    log_info "Tagging $source_image as $target_image..."
    if docker tag "$source_image" "$target_image"; then
        log_info "Successfully tagged image"
    else
        log_error "Failed to tag image"
        return 1
    fi
    
    log_info "Pushing $target_image..."
    if docker push "$target_image"; then
        log_info "Successfully pushed $target_image"
        return 0
    else
        log_error "Failed to push $target_image"
        return 1
    fi
}

# Main execution
main() {
    log_info "Starting image migration process..."
    log_info "Source Registry: $SOURCE_REGISTRY"
    log_info "Target Registry: $TARGET_REGISTRY"
    log_info "Images CSV: $IMAGES_CSV"
    
    # Authenticate
    docker_login || exit 1
    
    # Read images from CSV
    images=$(read_images) || exit 1
    
    total=$(echo "$images" | wc -l)
    counter=0
    failed_images=()
    
    log_info "Found $total images to migrate"
    
    # Process each image
    while IFS= read -r image; do
        ((counter++))
        log_info "[$counter/$total] Processing: $image"
        
        if pull_image "$image" && tag_and_push "$image"; then
            log_info "[$counter/$total] ✓ Successfully migrated: $image"
        else
            log_error "[$counter/$total] ✗ Failed to migrate: $image"
            failed_images+=("$image")
        fi
        
        echo ""
    done <<< "$images"
    
    # Summary
    echo ""
    log_info "Migration process completed"
    log_info "Total images: $total"
    log_info "Successful: $((total - ${#failed_images[@]}))"
    log_info "Failed: ${#failed_images[@]}"
    
    if [ ${#failed_images[@]} -gt 0 ]; then
        log_error "Failed images:"
        for img in "${failed_images[@]}"; do
            echo "  - $img"
        done
        exit 1
    else
        log_info "All images migrated successfully!"
        exit 0
    fi
}

# Run main function
main "$@"
