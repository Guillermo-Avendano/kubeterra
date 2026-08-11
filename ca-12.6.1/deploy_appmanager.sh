#!/bin/bash
set -Eeuo pipefail

install_appmanager() {

	APPAMANGER_STORAGE_FILE=appmanager_storage.yaml;
  cp $kube_dir/appmanager/storage/local/templates/$APPAMANGER_STORAGE_FILE $kube_dir/appmanager/storage/local/$APPAMANGER_STORAGE_FILE;

	replace_tag_in_file $kube_dir/appmanager/storage/local/$APPAMANGER_STORAGE_FILE "<APPMANAGER_PV_VOLUME>" $APPMANAGER_PV_VOLUME;

  APPMANAGER_VALUES_FILE=appmanager.yaml;
  cp $kube_dir/appmanager/templates/$APPMANAGER_VALUES_FILE $kube_dir/appmanager/$APPMANAGER_VALUES_FILE;
  replace_tag_in_file $kube_dir/appmanager/$APPMANAGER_VALUES_FILE "<NAME_LOCALREGISTRY>" $NAME_LOCALREGISTRY;
	replace_tag_in_file $kube_dir/appmanager/$APPMANAGER_VALUES_FILE "<PORT_LOCALREGISTRY>" $PORT_LOCALREGISTRY;
	replace_tag_in_file $kube_dir/appmanager/$APPMANAGER_VALUES_FILE "<IMAGE_NAME_APPMANAGER>" $IMAGE_NAME_APPMANAGER;
	replace_tag_in_file $kube_dir/appmanager/$APPMANAGER_VALUES_FILE "<IMAGE_VERSION_APPMANAGER>" $IMAGE_VERSION_APPMANAGER;
	replace_tag_in_file $kube_dir/appmanager/$APPMANAGER_VALUES_FILE "<POSTGRESQL_USERNAME>" $POSTGRESQL_USERNAME;
	replace_tag_in_file $kube_dir/appmanager/$APPMANAGER_VALUES_FILE "<POSTGRESQL_PASSWORD>" $POSTGRESQL_PASSWORD;
	replace_tag_in_file $kube_dir/appmanager/$APPMANAGER_VALUES_FILE "<POSTGRESQL_HOST>" $POSTGRESQL_HOST;
	replace_tag_in_file $kube_dir/appmanager/$APPMANAGER_VALUES_FILE "<POSTGRESQL_PORT>" $POSTGRESQL_PORT;
	replace_tag_in_file $kube_dir/appmanager/$APPMANAGER_VALUES_FILE "<POSTGRESQL_DBNAME_APPMANAGER>" $POSTGRESQL_DBNAME_APPMANAGER;
	replace_tag_in_file $kube_dir/appmanager/$APPMANAGER_VALUES_FILE "<NAMESPACE>" $NAMESPACE;
  replace_tag_in_file $kube_dir/appmanager/$APPMANAGER_VALUES_FILE "<MOBIUSVIEW_SECURITY_JWT_PRIVATEKEY>" $MOBIUSVIEW_SECURITY_JWT_PRIVATEKEY;
  replace_tag_in_file $kube_dir/appmanager/$APPMANAGER_VALUES_FILE "<MOBIUSVIEW_SECURITY_JWT_PUBLICKEY>" $MOBIUSVIEW_SECURITY_JWT_PUBLICKEY;

  info_message "Creating appmanager storage";
  $KUBE_CLI_EXE apply -f $kube_dir/appmanager/storage/local/appmanager_storage.yaml --namespace $NAMESPACE;

 info_message "Deploy appmanager";
 helm upgrade appmanager -n $NAMESPACE $kube_dir/helm_charts/appmanager.tgz -f $kube_dir/appmanager/appmanager.yaml --install

 	info_message "Clean up resources";
  rm -f $kube_dir/appmanager/storage/local/$APPAMANGER_STORAGE_FILE
  rm -f $kube_dir/appmanager/$APPMANAGER_VALUES_FILE
}

wait_for_appmanager_ready() {
    info_message "Waiting for appmanager to be ready";
    COUNTER=0
	output=`kubectl get pods -n $NAMESPACE -o go-template --template '{{range .items}}{{if eq (.status.phase) ("Running")}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}'`
    until [[ "$output" == *appmanager* ]]
    do
        info_progress "...";
		let COUNTER=COUNTER+5
		if [[ "$COUNTER" -gt 300 ]]; then
		  echo "FATAL: Failed to install appmanager. Please check logs and configuration"
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

kube_init;
APPMANAGER_PV_VOLUME=`eval echo ~/${NAMESPACE}_data/appmanager/pv`
install_appmanager;
wait_for_appmanager_ready;
