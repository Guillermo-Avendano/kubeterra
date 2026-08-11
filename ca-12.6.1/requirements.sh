#!/bin/bash

show_help() {
    local blue=`tput setaf 4`
    local green=`tput setaf 2`
    local reset=`tput sgr0`

    highlight_message "HELP"
    echo -e "Run requirements.sh to install the requirements that you need to create the infrastructure and deploy Zenith services."
    echo -e "Depending on the kubernetes provider you will use, the requirements that will be installed will be different.\n"

    echo -e "requirements.sh <kubernetes provider>\n"
    echo -e "Example :-"    
    echo -e "${green}requirements.sh k3d${reset}\n"    
    echo -e "Parameters:"
    echo -e "  - kubernetes provider: ${blue}MANDATORY${reset}. It is the Kubernetes provider that you will use in your environment."
    echo -e "     * ${green}minikube${reset}: It installs the requisites required to create an environment in minikube."
    echo -e "     * ${green}k3d${reset}: It installs the requisites required to create an environment in k3d."
    echo -e "     * ${green}eks${reset}: It installs the requisites required to create an environment in EKS."
    echo -e "     * ${green}rosa${reset}: It installs the requisites required to create an environment in Red Hat OpenShift Service on AWS ( ROSA )."
    echo -e "     * ${green}crc${reset}: It installs the requisites required to create an crc environment in Red Hat OpenShift or in compatible Red Hat distribution."
    echo -e "     * ${green}okd${reset}: It installs the requisites required to create an OKD environment on AWS"
    echo -e "     * ${green}help${reset}: It displays the help."
    echo -e ""
    
}

kube_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
[ -d "$kube_dir" ] || {
    echo "FATAL: no current dir (maybe running in zsh?)"
    exit 1
}

source "$kube_dir/common/common.sh"

detect_os;

if [ $# -ge 1 ]; then

  if [ "${args[0]}" == "help" ]; then
    show_help;
    exit 1;
  fi

  kubernetes=${1:-k3d}
  # Default kubernetes provider is k3d. 
  # eks is also available and minikube is not completely done.
  sh platforms/${OS}/config.sh $kubernetes
else
  # Default kubernetes provider is k3d.
  kubernetes=k3d
  sh platforms/${OS}/config.sh $kubernetes
  #exit 1;
fi
