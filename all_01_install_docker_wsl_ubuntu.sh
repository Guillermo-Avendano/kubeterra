#!/bin/bash
source lib/common.sh
set -Eeuo pipefail

# Set the CORE_SCRIPTS_DIR to the directory containing this script.
CORE_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"

# Source the common and registry scripts.
source "$CORE_SCRIPTS_DIR/common.sh"


# Get the current logged-in user
CURRENT_USER=$(whoami)

log INFO "--- Starting Docker and Docker Compose Installation Script ---"

# --- SUDO NOPASSWD CONFIGURATION ---
## WARNING: This section grants passwordless root access. Use with extreme caution.
log INFO "1. Configuring sudo NOPASSWD for user: $CURRENT_USER"
SUDOERS_FILE="/etc/sudoers.d/99-${CURRENT_USER}-nopasswd"

# Check and set NOPASSWD configuration
if sudo grep -q "^${CURRENT_USER} ALL=(ALL) NOPASSWD: ALL$" /etc/sudoers.d/* 2>/dev/null; then
    log INFO "    - NOPASSWD configuration already exists for this user."
else
    # Create the NOPASSWD configuration file
    echo "${CURRENT_USER} ALL=(ALL) NOPASSWD: ALL" | sudo tee "$SUDOERS_FILE" > /dev/null
    # Ensure correct permissions for the sudoers.d file
    sudo chmod 0440 "$SUDOERS_FILE"
    log INFO "    - 'NOPASSWD' configuration added to $SUDOERS_FILE."
fi

log INFO ""

# ----------------------------------------------------------------------
# --- NEW BLOCK: APT Repository Cleanup (Fixes GPG/Signature errors) ---
# ----------------------------------------------------------------------
log INFO "2. Checking for and cleaning up problematic external APT repositories..."
# The system often fails 'apt update' due to old MySQL or MariaDB entries.
# Find and remove any list files referencing MySQL (often named mysql.list)
find /etc/apt/sources.list.d/ -type f -name '*mysql*.list' -delete 2>/dev/null || true
log INFO "    - Removed old MySQL repository configuration files."

# Clean up MariaDB repos if they are causing issues (Optional, but often necessary)
find /etc/apt/sources.list.d/ -type f -name '*mariadb*.list' -delete 2>/dev/null || true
log INFO "    - Removed old MariaDB repository configuration files."

log INFO ""
# --- END NEW BLOCK ---
# ----------------------------------------------------------------------

# --- CLEAN UP OLD DOCKER INSTALLATIONS ---
log INFO "3. Cleaning up old Docker installations..."
# Note: The step numbering changed from 2 to 3 due to the added cleanup block.
sudo apt-get remove -y docker docker-engine docker.io containerd runc docker-ce docker-ce-cli containerd.io docker-compose-plugin 2>/dev/null || true
log INFO "    - Old package cleanup completed."
log INFO ""

# --- IPTABLES LEGACY CONFIGURATION ---
log INFO "4. Configuring iptables to legacy mode (if supported)..."
# Install iptables-persistent to provide the 'legacy' alternatives, avoiding the "no alternatives" error.
sudo apt-get install -y iptables-persistent 2>/dev/null || true
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy || true
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy || true
log INFO "    - iptables configuration completed."
log INFO ""

# --- INSTALL LATEST DOCKER ENGINE AND COMPOSE PLUGIN ---
log INFO "5. Installing the LATEST stable version of Docker Engine and Docker Compose Plugin..."
# Note: The step numbering changed from 4 to 5.

# Update package list and install dependencies
# This 'update' should now succeed after cleaning up external repos.
sudo apt-get update 
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Add Docker's GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add the Docker repository to APT sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package list again with the new repository
sudo apt-get update

# Install the latest stable version of Docker components, including docker-compose-plugin
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

log INFO "    - Installation of Docker Engine, CLI, Containerd, and Compose Plugin completed."
log INFO ""

# --- DOCKER SERVICE MANAGEMENT ---
log INFO "6. Enabling and verifying the Docker service..."
# Note: The step numbering changed from 5 to 6.

# Enable and start docker service
sudo systemctl enable docker
sudo systemctl start docker

# Check the service status
if sudo systemctl is-active --quiet docker; then
    log INFO "    ✅ Docker service is active and running."
else
    log ERROR "    ❌ Docker service is NOT running. Check logs with 'journalctl -xeu docker'."
fi
log INFO ""

# --- DOCKER GROUP CONFIGURATION ---
log INFO "7. Adding the current user ($CURRENT_USER) to the 'docker' group..."
# Note: The step numbering changed from 6 to 7.

# Create the docker group if it doesn't exist
sudo groupadd docker || true

# Add the current user to the docker group
sudo usermod -aG docker "$CURRENT_USER"

log INFO "    - User $CURRENT_USER has been added to the 'docker' group."
log INFO ""

# --- CREATE DOCKER-COMPOSE ALIAS (FOR LEGACY COMMAND) ---
log INFO "8. Creating 'docker-compose' alias (symlink) for legacy compatibility..."
# Note: The step numbering changed from 7 to 8.

# The modern plugin is at /usr/libexec/docker/cli-plugins/docker-compose
# We create a symlink to use the old command name: docker-compose
if [ -f /usr/libexec/docker/cli-plugins/docker-compose ]; then
    sudo ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
    log INFO "    - Symlink created: '/usr/local/bin/docker-compose' now points to the plugin."
elif [ -f /usr/lib/docker/cli-plugins/docker-compose ]; then
    # This path is common in some older Ubuntu/Debian installs.
    sudo ln -s /usr/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
    log INFO "    - Symlink created: '/usr/local/bin/docker-compose' now points to the plugin."
else
    log WARN "    - WARNING: Could not find the docker-compose plugin location to create the symlink."
fi
log INFO ""

# --- VERIFY INSTALLATION ---
log INFO "9. Verifying installations..."
# Note: The step numbering changed from 8 to 9.
log INFO "    - Docker Version (docker --version):"
docker --version
log INFO "    - Docker Compose Plugin Version (docker compose version):"
docker compose version
log INFO "    - Legacy Docker Compose Command Check (docker-compose --version):"
docker-compose --version || log WARN "    - NOTE: The legacy command failed, you might need to run 'newgrp docker' first."
log INFO ""

log INFO "--- Script execution finished ---"
log WARN "ATTENTION: To use 'docker' and 'docker-compose' commands without 'sudo' IMMEDIATELY,"
log WARN "!!!! =====>>>>>> YOU MUST RUN: newgrp docker"
log WARN "Otherwise, the group change will only take effect after you log out and log back in."