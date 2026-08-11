#!/bin/bash

command_exists() {
	[ -x "$1" ] || command -v $1 >/dev/null 2>/dev/null
}

replace_tag_in_file() {
    local filename=$1
    local search=$2
    local replace=$3

    if [[ $search != "" && $replace != "" ]]; then
        # Escape not allowed characters in sed tool
        search=$(printf '%s\n' "$search" | sed -e 's/[]\/$*.^[]/\\&/g');
        replace=$(printf '%s\n' "$replace" | sed -e 's/[]\/$*.^[]/\\&/g');
        sed -i'' -e "s/$search/$replace/g" $filename
    fi
}

replace_array_in_file() {
    local file=$1
    local tag=$2
    local array_string=$3

    # Convert comma-separated string into YAML list
    local array_yaml=""
    IFS=',' read -ra ADDR <<< "$array_string"
    for item in "${ADDR[@]}"; do
        array_yaml+="  - $item\n"
    done

    # Replace the placeholder with the YAML-formatted array
    sed -i "s|${tag}|${array_yaml//$'\n'/\\n}|g" "$file"
}

highlight_message() {
    local yellow=`tput setaf 3`
    local reset=`tput sgr0`

    echo -e "\r"
    echo "${yellow}********************************************${reset}"
    echo "${yellow}**${reset} $1 "
    echo "${yellow}********************************************${reset}"
}

info_message() {
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

detect_os() {
    case "$(uname -a)" in
      *microsoft*) OS="debian";; # WSL2
      *Microsoft*) OS="debian";; # WSL1
      *-Ubuntu*)   OS="debian";;
      Linux*)      OS="rhel";;   # Red Hat
      Darwin*)     OS="darwin";;
      *)           OS="UNKNOWN"
    esac
    if [ "${OS}" == "rhel" ]; then
      case "$(grep '^NAME=' /etc/os-release | awk -F= '{print $2}')" in
        *CentOS*) OS="centos" # CentOS
      esac
    fi
}	
