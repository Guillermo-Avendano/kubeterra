#!/bin/bash

# This script provides tools for managing Docker images.
# It can be run interactively (without arguments) or with direct commands (with an argument).

# Set the CORE_SCRIPTS_DIR to the directory containing this script.

CORE_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the common and registry scripts.
# NOTE: It is assumed that these functions exist:
# pull_images, tag_images, push_images, list_images, list_images_local, ask_binary_question, log
source "$CORE_SCRIPTS_DIR/common.sh"
source "$CORE_SCRIPTS_DIR/registry.sh"
source "$CORE_SCRIPTS_DIR/kubefuncions.sh"
source "$CORE_SCRIPTS_DIR/certificates.sh"
source "$CORE_SCRIPTS_DIR/ingress.sh"

# Detect OS
detect_os
log INFO "Detected OS: $OS"

# --- Utility Functions ---

check_nfs(){
    
  log INFO "✅ NFS Packages installed."
  
  if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
      dpkg -l | grep nfs-common
      dpkg -l | grep nfs-kernel-server
  elif [ "$OS" = "rhel" ] || [ "$OS" = "centos" ] || [ "$OS" = "rocky" ] || [ "$OS" = "fedora" ]; then
      rpm -qa | grep nfs-utils
  else
      log WARN "Unknown OS: $OS. Skipping package check."
  fi

  log INFO "✅ NFS Server Path."
  ls -ld $NFS_SERVER_PATH

  log INFO "✅ cat /etc/exports"
  cat /etc/exports

}

# Cleans all Docker images, volumes, and containers
clean_docker(){
    log WARN "⚠️ WARNING: This will remove ALL Docker containers, images, and volumes!"
    
    if [[ $(ask_binary_question "Are you sure you want to continue?" "false") != "Y" ]]; then
        log INFO "Operation cancelled by user."
        return 0
    fi
    
    log INFO "🧹 Starting Docker cleanup..."
    
    # Stop all running containers
    log INFO "Stopping all running containers..."
    if [ -n "$(docker ps -q)" ]; then
        docker stop $(docker ps -q) 2>/dev/null || log WARN "No running containers to stop."
    else
        log INFO "No running containers found."
    fi
    
    # Remove all containers (running and stopped)
    log INFO "Removing all containers..."
    if [ -n "$(docker ps -aq)" ]; then
        docker rm -f $(docker ps -aq) 2>/dev/null || log WARN "No containers to remove."
    else
        log INFO "No containers found."
    fi
    
    # Remove all images
    log INFO "Removing all images..."
    if [ -n "$(docker images -q)" ]; then
        docker rmi -f $(docker images -q) 2>/dev/null || log WARN "No images to remove."
    else
        log INFO "No images found."
    fi
    
    # Remove all volumes
    log INFO "Removing all volumes..."
    if [ -n "$(docker volume ls -q)" ]; then
        docker volume rm $(docker volume ls -q) 2>/dev/null || log WARN "No volumes to remove."
    else
        log INFO "No volumes found."
    fi
    
    # Remove all networks (except default ones)
    log INFO "Removing custom networks..."
    if [ -n "$(docker network ls --filter type=custom -q)" ]; then
        docker network rm $(docker network ls --filter type=custom -q) 2>/dev/null || log WARN "No custom networks to remove."
    else
        log INFO "No custom networks found."
    fi
    
    # Prune system to remove any remaining unused data
    log INFO "Pruning system..."
    docker system prune -af --volumes 2>/dev/null || true
    
    log INFO "✅ Docker cleanup completed!"
    log INFO "Current Docker disk usage:"
    docker system df
}

# Displays the menu options.
show_menu() {
    log INFO "Namespce: $NAMESPACE"
    log INFO "Images: ./conf/images.csv"
    log INFO "Ingress: ./conf/ingress.csv"
    log INFO "Please select an option (or use the script with a parameter, e.g.: ./tools.sh pull):"
    log INFO "1. pull    - Pull, Tag, and Push images."
    log INFO "2. remote  - List remote images."
    log INFO "3. local   - List local images."
    log INFO "4. nfs     - Check NFS."
    log INFO "5. debug   - Creates information about the cluster in logs directory."
    log INFO "6. ingress - Creates ingress for mobius services."
    log INFO "7. nginx   - Installs NGINX http=8080/https=8443."
    log INFO "Z. clean   - Clean all Docker containers, images, and volumes."
    log INFO "X. exit    - Exit."
}

# Displays usage instructions.
show_usage() {
    log INFO "Usage: $0 [command]"
    log INFO ""
    log INFO "Available commands (Numeric options also work as commands):"
    log INFO "  1 | pull | ptp    : Performs the full cycle: Pull, Tag, and Push images."
    log INFO "  2 | remote | ls-r : Lists images from the remote registry."
    log INFO "  3 | local | ls-l  : Lists local images."
    log INFO "  4 | nfs           : Check NFS."
    log INFO "  5 | debug         : Creates information about the cluster in logs directory."
    log INFO "  6 | ingress       : Creates ingress for mobius services (conf/ingress)."
    log INFO "  7 | nginx         : Installs NGINX http=8080/https=8443."
    log INFO "  Z | clean         : Clean all Docker containers, images, and volumes."
    log INFO "  menu              : Shows the interactive menu."
    log INFO "  help              : Shows this help message."
}

# Executes the command passed as an argument.
execute_command() {
    local command="$1"
    case "$command" in
        # Full cycle: Pull, Tag, Push (Option 1)
        1 | pull | tag | push | ptp)
            log INFO "🚀 Executing Pull, Tag, and Push..."
            if [[ $(ask_binary_question "Do you want to pull images?" "false") == "Y" ]]; then
                pull_images
            fi
            tag_images
            if [[ $(ask_binary_question "Do you want to push the images?" "false") == "Y" ]]; then
                push_images
            fi
            ;;
        # List remote (Option 2)
        2 | remote | ls-r)
            log INFO "🔍 Listing remote images..."
            list_images
            ;;
        # List local (Option 3)
        3 | local | ls-l)
            log INFO "📦 Listing local images..."
            list_images_local
            ;;
        4 | nfs | ls-l)
            log INFO "📦 Check NFS Installation..."
            check_nfs
            ;;  
        5 | debug | ls-l)
            log INFO "📦 Debug Namespaces..."
            debug_namespaces
            ;;
        6 | ingress | ls-l)
            log INFO "📦 Creating Ingresses for Mobius..."
            install_ingress;
            ;;
        7 | nginx | ls-l)
            log INFO "📦 Installing NGINX..."
            update_nginx;
            ;;            
        z | clean)
            log INFO "🧹 Cleaning Docker..."
            clean_docker
            ;;                         
        # Exit (Option 4)
        x | exit)
            log INFO "Exiting script. Goodbye!"
            exit 0
            ;;
        menu)
            log INFO "Menu manually invoked."
            run_interactive_menu
            ;;
        help)
            show_usage
            ;;
        *)
            log ERROR "Invalid option or command: $command. Use '$0 help' for options."
            exit 1
            ;;
    esac
}

# Interactive menu mode.
run_interactive_menu() {
    while true; do
        show_menu
        read -p "Enter your choice (1-6, X to exit): " choice
        
        # Executes the chosen command using the current function's logic
        execute_command "$choice"
        log INFO "---"
    done
    log INFO "Exiting script. Goodbye!"
}

# --- Main Logic ---

main() {
    if [ "$#" -eq 0 ]; then
        # No parameters: Run interactive mode (menu)
        run_interactive_menu
    else
        # With parameters: Execute the command passed as the first argument
        execute_command "$1"
    fi
}

# Call the main function.
main "$@"