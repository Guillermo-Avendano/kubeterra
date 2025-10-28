#!/bin/bash
# common.sh: Utility functions for k3d cluster management scripts
# Usage: source common.sh; command_exists <cmd> | replace_tag_in_file <file> <search> <replace> | log <level> <message> | ...
# Requires: bash, tput, sed, MYDEBUG

set -Eeuo pipefail

# Function to log messages
# Parameters:
#   $1: Level (INFO, ERROR, WARN, PROGRESS)
#   $2: Message to display
log() {
    local level="$1"
    local message="$2"
    local log_file="$HOME/cluster.log"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color reset="\033[0m"

    case "$level" in
        INFO)     color="\033[1;32m" ;; # Green
        ERROR)    color="\033[1;31m" ;; # Red
        WARN)     color="\033[1;33m" ;; # Yellow
        PROGRESS) color="\033[1;33m" ;; # Yellow
        *)        color="\033[0m"    ;;
    esac

    if [ "$level" == "PROGRESS" ]; then
        echo -ne "${color}>>>>> ${message}${reset}" >&2
    else
        echo -e "${color}${timestamp} [$level] ${message}${reset}" >&2
        #mkdir -p "$(dirname "$log_file")" 2>/dev/null
        #echo "${timestamp} [$level] ${message}" >> "$log_file" 2>/dev/null
    fi
}

# Function to display help
common_usage() {
    cat << EOF
Usage: source $0; <function> [arguments]

Functions:
  command_exists <command>          Checks if a command is available
  replace_tag_in_file <file> <search> <replace>  Replaces a string in a file
  log <level> <message>            Logs a message (levels: INFO, ERROR, WARN, PROGRESS)
  detect_os                        Detects the operating system
  ask_binary_question <question> <quiet>  Prompts for a yes/no answer

Examples:
  source common.sh; command_exists kubectl
  source common.sh; replace_tag_in_file config.yaml old new
  source common.sh; log INFO "Starting operation"

Dependencies: bash, tput, sed, MYDEBUG
Logs are saved to: ~/.k3d/common.log
EOF
    exit 0
}

# Function to check if a command exists
# Parameters:
#   $1: Command to check
# Returns: 0 if command exists, 1 otherwise
command_exists() {
    local cmd="$1"
    if [ -z "$cmd" ]; then
        log ERROR "No command provided to command_exists."
        return 1
    fi
    if [ -x "$cmd" ] || command -v "$cmd" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to replace a string in a file
# Parameters:
#   $1: File path
#   $2: String to search
#   $3: Replacement string
replace_tag_in_file() {
    local filename="$1"
    local search="$2"
    local replace="$3"

    if [ -z "$filename" ] || [ -z "$search" ]; then
        log ERROR "Filename or search string is empty."
        return 1
    fi

    if [ ! -f "$filename" ]; then
        log ERROR "File $filename does not exist."
        return 1
    fi

    if [ ! -w "$filename" ]; then
        log ERROR "File $filename is not writable."
        return 1
    fi

    if [ "${MYDEBUG:-false}" == "true" ]; then
        echo "sed -i'' -e 's/$search/$replace/g' $filename"
    else
        # Escape special characters for sed
        search=$(printf '%s\n' "$search" | sed -e 's/[]\/$*.^[]/\\&/g')
        replace=$(printf '%s\n' "$replace" | sed -e 's/[]\/$*.^[]/\\&/g')
        sed -i'' -e "s/$search/$replace/g" "$filename" || {
            log ERROR "Failed to replace '$search' with '$replace' in $filename."
            return 1
        }
    fi

    log INFO "Replaced '$search' with '$replace' in $filename."
}

# Function to detect the operating system
# Sets global variable OS to: debian, rhel, centos, darwin, or UNKNOWN
detect_os() {
    local os_id
    os_id=$(awk -F'=' '/^ID=/ { gsub("\"","",$2); print tolower($2) }' /etc/*-release 2>/dev/null || echo "")

    case "$os_id" in
        *debian*)    OS="debian"  ;;
        *ubuntu*)    OS="debian"  ;;
        *rhel*)      OS="rhel"    ;;
        *centos*)    OS="centos"  ;;
        *rocky*)     OS="rocky"   ;;
        *fedora*)    OS="fedora"  ;;
        *alpine*)    OS="alpine"  ;;
        darwin*)     OS="darwin"  ;;
        *)           OS="UNKNOWN" ;;
    esac

    if [ "$OS" == "UNKNOWN" ] && [ -n "$(uname -s | grep -i Darwin)" ]; then
        OS="darwin"
    fi

    log INFO "Detected operating system: $OS"
    export OS
}

# Function to prompt for a yes/no answer
# Parameters:
#   $1: Question to display
#   $2: Quiet mode (true/false)
# Returns: Y or N
ask_binary_question() {
    local question="$1"
    local quiet="${2:-false}"
    local answer="Y"

    if [ -z "$question" ]; then
        log ERROR "No question provided to ask_binary_question."
        return 1
    fi

    if [ "$quiet" != "true" ]; then
        while true; do
            read -p "$question " yn
            case "$yn" in
                [Yy]* ) answer="Y"; break ;;
                [Nn]* ) answer="N"; break ;;
                * ) log WARN "Please answer yes (y) or no (n)." ;;
            esac
        done
    fi

    log INFO "User answered '$answer' to question: $question"
    echo "$answer"
}

command_exists() {
	[ -x "$1" ] || command -v $1 >/dev/null 2>/dev/null
}


highlight_message() {
    local yellow=`tput setaf 3`
    local reset=`tput sgr0`

    echo -e "\r"
    echo "${yellow}********************************************${reset}"
    echo "${yellow}**${reset} $1 "
    echo "${yellow}********************************************${reset}"
}

info_message () {
    local yellow=`tput setaf 3`
    local reset=`tput sgr0`

    echo -e "\r"
    echo "${yellow}>>>>>${reset} $1"
}

error_message() {
    local yellow=`tput setaf 3`
    local red=`tput setaf 1`
    local reset=`tput sgr0`

    echo -e "\r"
    echo "${yellow}>>>>>${reset} ${red} Error: $1${reset}"
}

info_progress_header() {
    local yellow=`tput setaf 3`
    local reset=`tput sgr0`

    echo -e "\r"
    echo -n "${yellow}>>>>>${reset} $1"
}

info_progress() {
    echo -n "$1"
}