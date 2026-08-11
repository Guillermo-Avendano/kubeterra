#!/bin/bash
set -Eeuo pipefail

install_mobius() {

	MOBIUS_STORAGE_FILE=mobius_storage.yaml;
  cp $kube_dir/mobius/storage/local/templates/$MOBIUS_STORAGE_FILE $kube_dir/mobius/storage/local/$MOBIUS_STORAGE_FILE;
	
	replace_tag_in_file $kube_dir/mobius/storage/local/$MOBIUS_STORAGE_FILE "<MOBIUS_DIAGNOSTIC_VOLUME>" $MOBIUS_DIAGNOSTIC_VOLUME;
	replace_tag_in_file $kube_dir/mobius/storage/local/$MOBIUS_STORAGE_FILE "<MOBIUS_FTS_VOLUME>" $MOBIUS_FTS_VOLUME;
	replace_tag_in_file $kube_dir/mobius/storage/local/$MOBIUS_STORAGE_FILE "<MOBIUS_PV_VOLUME>" $MOBIUS_PV_VOLUME;
	
	MOBIUS_VALUES_FILE=mobiusserver.yaml;
  cp $kube_dir/mobius/templates/$MOBIUS_VALUES_FILE $kube_dir/mobius/$MOBIUS_VALUES_FILE;
	replace_tag_in_file $kube_dir/mobius/$MOBIUS_VALUES_FILE "<NAME_LOCALREGISTRY>" $NAME_LOCALREGISTRY;
	replace_tag_in_file $kube_dir/mobius/$MOBIUS_VALUES_FILE "<PORT_LOCALREGISTRY>" $PORT_LOCALREGISTRY;
	replace_tag_in_file $kube_dir/mobius/$MOBIUS_VALUES_FILE "<IMAGE_NAME_MOBIUS>" $IMAGE_NAME_MOBIUS;
	replace_tag_in_file $kube_dir/mobius/$MOBIUS_VALUES_FILE "<IMAGE_VERSION_MOBIUS>" $IMAGE_VERSION_MOBIUS;
	replace_tag_in_file $kube_dir/mobius/$MOBIUS_VALUES_FILE "<RDSINITORUPGRADE>" $RDSINITORUPGRADE;
	replace_tag_in_file $kube_dir/mobius/$MOBIUS_VALUES_FILE "<POSTGRESQL_USERNAME>" $POSTGRESQL_USERNAME;
	replace_tag_in_file $kube_dir/mobius/$MOBIUS_VALUES_FILE "<POSTGRESQL_PASSWORD>" $POSTGRESQL_PASSWORD;
	replace_tag_in_file $kube_dir/mobius/$MOBIUS_VALUES_FILE "<POSTGRESQL_HOST>" $POSTGRESQL_HOST;
	replace_tag_in_file $kube_dir/mobius/$MOBIUS_VALUES_FILE "<POSTGRESQL_PORT>" $POSTGRESQL_PORT;
	replace_tag_in_file $kube_dir/mobius/$MOBIUS_VALUES_FILE "<POSTGRESQL_DBNAME_MOBIUS>" $POSTGRESQL_DBNAME_MOBIUS;
	replace_tag_in_file $kube_dir/mobius/$MOBIUS_VALUES_FILE "<NAMESPACE>" $NAMESPACE;
	replace_tag_in_file $kube_dir/mobius/$MOBIUS_VALUES_FILE "<ELASTICSEARCH_INDEX>" $SMART_CHAT_INDEX;

	if [ "$SMART_CHAT_ENABLED" == "true" ]; then
      ELASTICSEARCH_HOST="smart-chat-indexing-proxy";
      ELASTICSEARCH_PORT="80";
      replace_tag_in_file $kube_dir/mobius/$MOBIUS_VALUES_FILE "<ELASTICSEARCH_HOST>" $ELASTICSEARCH_HOST;
      replace_tag_in_file $kube_dir/mobius/$MOBIUS_VALUES_FILE "<ELASTICSEARCH_PORT>" $ELASTICSEARCH_PORT;
  fi

	reconcile_mobius_shared_storage;

  info_message "Creating mobius storage";
  $KUBE_CLI_EXE apply -f $kube_dir/mobius/storage/local/mobius_storage.yaml --namespace $NAMESPACE;
	
	info_message "Deploy mobius"; 
	helm upgrade mobius -n $NAMESPACE $kube_dir/helm_charts/mobius.tgz -f $kube_dir/mobius/mobiusserver.yaml --install

	info_message "Clean up resources";
  rm -f $kube_dir/mobius/storage/local/$MOBIUS_STORAGE_FILE
  rm -f $kube_dir/mobius/$MOBIUS_VALUES_FILE
}

wait_for_mobius_ready() {
    info_message "Waiting for mobius to be ready";
    COUNTER=0
	output=`kubectl get pods -n $NAMESPACE -o go-template --template '{{range .items}}{{if eq (.status.phase) ("Running")}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}'`
    until [[ "$output" == *mobius* ]]
    do
        info_progress "...";
		let COUNTER=COUNTER+5
		if [[ "$COUNTER" -gt 300 ]]; then
		  echo "FATAL: Failed to install mobius. Please check logs and configuration"
          exit 1    
		fi
        sleep 5;
		output=`kubectl get pods -n $NAMESPACE -o go-template --template '{{range .items}}{{if eq (.status.phase) ("Running")}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}'`
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
source "$kube_dir/common/mobius_shared_storage.sh"

kube_init;

MOBIUS_PV_VOLUME=`eval echo ~/${NAMESPACE}_data/mobius/pv`
MOBIUS_FTS_VOLUME=`eval echo ~/${NAMESPACE}_data/mobius/fts`
MOBIUS_DIAGNOSTIC_VOLUME=`eval echo ~/${NAMESPACE}_data/mobius/log`

install_mobius;
wait_for_mobius_ready;