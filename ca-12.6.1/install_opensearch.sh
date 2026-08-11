#!/bin/bash
set -Eeuo pipefail

install_opensearch() {
    info_message "Installing opensearch";  
    info_message "Configuring opensearch $OPENSEARCH_VERSION resources";
  
    cp $kube_dir/opensearch/storage/local/templates/$OPENSEARCH_STORAGE_FILE $kube_dir/opensearch/storage/local/$OPENSEARCH_STORAGE_FILE;
	replace_tag_in_file $kube_dir/opensearch/storage/local/$OPENSEARCH_STORAGE_FILE "<OPENSEARCH_VOLUME>" $OPENSEARCH_VOLUME;
  
    $KUBE_CLI_EXE apply -f  $kube_dir/opensearch/storage/local/$OPENSEARCH_STORAGE_FILE --namespace $NAMESPACE

    
    cp $kube_dir/opensearch/templates/$OPENSEARCH_CONF_FILE $kube_dir/opensearch/$OPENSEARCH_CONF_FILE;
    replace_tag_in_file $kube_dir/opensearch/$OPENSEARCH_CONF_FILE "<OPENSEARCH_VERSION>" $OPENSEARCH_VERSION;
    replace_tag_in_file $kube_dir/opensearch/$OPENSEARCH_CONF_FILE  "<NAME_LOCALREGISTRY>" $NAME_LOCALREGISTRY;
	replace_tag_in_file $kube_dir/opensearch/$OPENSEARCH_CONF_FILE  "<PORT_LOCALREGISTRY>" $PORT_LOCALREGISTRY;

    info_message "Updating local Helm repository";

    info_message "Deploying opensearch Helm chart";

	helm install opensearch $kube_dir/helm_charts/opensearch.tgz --namespace $NAMESPACE  -f $kube_dir/opensearch/$OPENSEARCH_CONF_FILE \
  --set global.security.allowInsecureImages=true

	info_message "Clean up resources";
    rm -f $kube_dir/opensearch/$OPENSEARCH_CONF_FILE
    rm -f $kube_dir/opensearch/storage/local/$OPENSEARCH_STORAGE_FILE
}

get_opensearch_status() {
    $KUBE_CLI_EXE get pods --namespace $NAMESPACE opensearch-cluster-master-0 -o jsonpath="{.status.phase}" 2>/dev/null
}

wait_for_opensearch_ready() {
    info_message "Waiting for opensearch to be ready";
    COUNTER=0
    until [ "$(get_opensearch_status)" == "Running" ]
    do
        info_progress "...";
		let COUNTER=COUNTER+5
		if [[ "$COUNTER" -gt 600 ]]; then
		  echo "FATAL: Failed to install opensearch. Please check logs and configuration"
          exit 1    
		fi
        sleep 5;
    done
}

xargsflag="-d"
export $(grep -v '^#' .env | xargs ${xargsflag} '\n')
kube_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
[ -d "$kube_dir" ] || {
    echo "FATAL: no current dir (maybe running in zsh?)"
    exit 1
}

source "$kube_dir/common/common.sh"
source "$kube_dir/common/local_kube.sh"

kube_init;

OPENSEARCH_VERSION="${OPENSEARCH_VERSION:-2.12.0}";
OPENSEARCH_CONF_FILE=opensearch.yaml;
OPENSEARCH_VOLUME=`eval echo ~/${NAMESPACE}_data/opensearch`
OPENSEARCH_STORAGE_FILE=opensearch-storage.yaml;

install_opensearch;
wait_for_opensearch_ready;