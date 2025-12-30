#!/bin/bash
set -Eeuo pipefail

# Script to synchronize image versions from conf/images.csv to .env files
# This ensures conf/images.csv is the single source of truth

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGES_CSV="${SCRIPT_DIR}/conf/images.csv"
ENV_LOCAL="${SCRIPT_DIR}/.env.local"
ENV_EXAMPLE="${SCRIPT_DIR}/.env.example"

# Function to extract version from images.csv
get_image_version() {
    local image_name=$1
    local version=$(grep "^${image_name}:" "$IMAGES_CSV" | cut -d':' -f2)
    echo "$version"
}

# Function to update version in env file
update_env_file() {
    local file=$1
    local var_name=$2
    local new_version=$3
    
    if [ -f "$file" ]; then
        # Check if variable exists
        if grep -q "^${var_name}=" "$file"; then
            # Update existing variable
            sed -i "s/^${var_name}=.*/${var_name}=${new_version}/" "$file"
            echo "  Updated ${var_name}=${new_version} in $(basename $file)"
        else
            echo "  Warning: ${var_name} not found in $(basename $file)"
        fi
    else
        echo "  Warning: $(basename $file) not found"
    fi
}

echo "=========================================="
echo "Synchronizing image versions from conf/images.csv"
echo "=========================================="

# Check if images.csv exists
if [ ! -f "$IMAGES_CSV" ]; then
    echo "ERROR: $IMAGES_CSV not found!"
    exit 1
fi

# Extract versions from images.csv
MOBIUS_SERVER_VERSION=$(get_image_version "mobius-server")
MOBIUS_VIEW_VERSION=$(get_image_version "mobius-view")
EVENT_ANALYTICS_VERSION=$(get_image_version "eventanalytics")
SMART_CHAT_VERSION=$(get_image_version "smart-chat")
SMART_CHAT_QUERY_LOGS_VERSION=$(get_image_version "smart-chat-query-logs")
SMART_CHAT_INDEXING_PROXY_VERSION=$(get_image_version "smart-chat-indexing-proxy")

echo ""
echo "Image versions from conf/images.csv:"
echo "  mobius-server: ${MOBIUS_SERVER_VERSION}"
echo "  mobius-view: ${MOBIUS_VIEW_VERSION}"
echo "  eventanalytics: ${EVENT_ANALYTICS_VERSION}"
echo "  smart-chat: ${SMART_CHAT_VERSION}"
echo "  smart-chat-query-logs: ${SMART_CHAT_QUERY_LOGS_VERSION}"
echo "  smart-chat-indexing-proxy: ${SMART_CHAT_INDEXING_PROXY_VERSION}"
echo ""

# Update .env.local
if [ -f "$ENV_LOCAL" ]; then
    echo "Updating .env.local..."
    update_env_file "$ENV_LOCAL" "MOBIUS_SERVER_IMAGE" "$MOBIUS_SERVER_VERSION"
    update_env_file "$ENV_LOCAL" "MOBIUS_VIEW_IMAGE" "$MOBIUS_VIEW_VERSION"
    update_env_file "$ENV_LOCAL" "EVENT_ANALYTICS_IMAGE" "$EVENT_ANALYTICS_VERSION"
    update_env_file "$ENV_LOCAL" "SMART_CHAT_IMAGE" "$SMART_CHAT_VERSION"
    update_env_file "$ENV_LOCAL" "SMART_CHAT_QUERY_LOGS_IMAGE" "$SMART_CHAT_QUERY_LOGS_VERSION"
    update_env_file "$ENV_LOCAL" "SMART_CHAT_INDEXING_PROXY_IMAGE" "$SMART_CHAT_INDEXING_PROXY_VERSION"
    echo "✓ .env.local updated successfully"
else
    echo "⚠ .env.local not found. Creating from .env.example..."
    if [ -f "$ENV_EXAMPLE" ]; then
        cp "$ENV_EXAMPLE" "$ENV_LOCAL"
        echo "✓ Created .env.local from .env.example"
        echo "⚠ Please edit .env.local with your credentials before deploying"
    fi
fi

echo ""

# Update .env.example
if [ -f "$ENV_EXAMPLE" ]; then
    echo "Updating .env.example..."
    update_env_file "$ENV_EXAMPLE" "MOBIUS_SERVER_IMAGE" "$MOBIUS_SERVER_VERSION"
    update_env_file "$ENV_EXAMPLE" "MOBIUS_VIEW_IMAGE" "$MOBIUS_VIEW_VERSION"
    update_env_file "$ENV_EXAMPLE" "EVENT_ANALYTICS_IMAGE" "$EVENT_ANALYTICS_VERSION"
    update_env_file "$ENV_EXAMPLE" "SMART_CHAT_IMAGE" "$SMART_CHAT_VERSION"
    update_env_file "$ENV_EXAMPLE" "SMART_CHAT_QUERY_LOGS_IMAGE" "$SMART_CHAT_QUERY_LOGS_VERSION"
    update_env_file "$ENV_EXAMPLE" "SMART_CHAT_INDEXING_PROXY_IMAGE" "$SMART_CHAT_INDEXING_PROXY_VERSION"
    echo "✓ .env.example updated successfully"
fi

echo ""
echo "=========================================="
echo "✓ Image version synchronization complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Review changes in .env.local and .env.example"
echo "  2. Run: ./04_pullimages.sh (to pre-pull new images)"
echo "  3. Run: ./05_terraform.sh (to deploy with new versions)"
