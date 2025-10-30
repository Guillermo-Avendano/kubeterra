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
source "$CORE_SCRIPTS_DIR/env.sh"
source "$CORE_SCRIPTS_DIR/kubefuncions.sh"

# --- Utility Functions ---

check_nfs(){
    
  log INFO "✅ NFS Packages installed."
  dpkg -l | grep nfs-common
  dpkg -l | grep nfs-kernel-server

  log INFO "✅ NFS Server Path."
  ls -ld $NFS_SERVER_PATH

  log INFO "✅ cat /etc/exports"
  cat /etc/exports

}

# Displays the menu options.
show_menu() {
    log INFO "Please select an option (or use the script with a parameter, e.g.: ./script.sh pull):"
    log INFO "1. pull   - Pull, Tag, and Push images."
    log INFO "2. remote - List remote images."
    log INFO "3. local  - List local images."
    log INFO "4. nfs    - Check NFS."
    log INFO "5. debug  - Creates information about the cluster in logs directory."
    log INFO "X. exit   - Exit."
}

# Displays usage instructions.
show_usage() {
    log INFO "Usage: $0 [command]"
    log INFO ""
    log INFO "Available commands (Numeric options also work as commands):"
    log INFO "  1 | pull | ptp        : Performs the full cycle: Pull, Tag, and Push images."
    log INFO "  2 | remote | ls-r     : Lists images from the remote registry."
    log INFO "  3 | local | ls-l      : Lists local images."
    log INFO "  4 | nfs               : Check NFS."
    log INFO "  5 | debug             :Creates information about the cluster in logs directory."
    log INFO "  menu                  : Shows the interactive menu."
    log INFO "  help                  : Shows this help message."
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
        read -p "Enter your choice (1-5, X to exit): " choice
        
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