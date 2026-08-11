#!/bin/bash
#abort in case of cmd failure
set -Eeuo pipefail

xargsflag="-d"
export $(grep -v '^#' .env | xargs ${xargsflag} '\n')
kube_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
[ -d "$kube_dir" ] || {
    echo "FATAL: no current dir (maybe running in zsh?)"
    exit 1
}

source "$kube_dir/common/local_kube.sh"
source "$kube_dir/common/common.sh"

kube_init;

remove_mobius_stack() {
  PV_VOLUME_DIR=`eval echo ~/${NAMESPACE}_data`
  if [ -d "$PV_VOLUME_DIR" ]; then
    sudo chmod -R 777 $PV_VOLUME_DIR
  fi
  if check_cluster_exists; then
    remove_services;

    # Remove volumes & claims
    #kubectl delete pvc --all -n $NAMESPACE
    #kubectl delete pv --all -n $NAMESPACE

    #info_message "Deleting $KAFKA_VERSION resources";
    #$KUBE_CLI_EXE delete -f  $kube_dir/kafka/$KAFKA_CONF_FILE --namespace $NAMESPACE
    info_message "Removing existing cluster"
    kube_delete_cluster "${KUBE_CLUSTER_NAME:-mobius}";
    info_message "Waiting termination"
    sleep 10;
    if [ $# -ge 1 ] && ([ $1 == "--remove-storage" ] || [ $1 == "-r" ]) && [ -d "$PV_VOLUME_DIR" ]; then
      info_message "Removing associated storage"
      sudo rm -r $PV_VOLUME_DIR
    else
      info_message "Ignoring persistent volumes and its associated storage deletion"
    fi
  fi
}

remove_mobius_stack "$@";