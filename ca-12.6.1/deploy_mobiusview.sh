#!/bin/bash
set -Eeuo pipefail

reconcile_mobiusview_storage() {
	local reset_storage=false
	local pv_name=''
	local pvc_name=''
	local phase=''
	local deleting=''

	for pv_name in mobiusview-presentation-storage mobiusview-diagnostic-pv-storage; do
		phase=$($KUBE_CLI_EXE get pv "$pv_name" -o jsonpath='{.status.phase}' 2>/dev/null || true)
		if [ "$phase" == "Released" ]; then
			reset_storage=true
			break
		fi
	done

	for pvc_name in mobiusview-presentation-claim mobiusview-diagnostic-pv-claim; do
		if ! $KUBE_CLI_EXE get pvc "$pvc_name" -n "$NAMESPACE" >/dev/null 2>&1; then
			reset_storage=true
			break
		fi
		deleting=$($KUBE_CLI_EXE get pvc "$pvc_name" -n "$NAMESPACE" -o jsonpath='{.metadata.deletionTimestamp}' 2>/dev/null || true)
		if [ -n "$deleting" ]; then
			reset_storage=true
			break
		fi
	done

	if [ "$reset_storage" == "true" ]; then
		info_message "Resetting stale mobiusview storage resources";
		$KUBE_CLI_EXE delete pvc mobiusview-presentation-claim mobiusview-diagnostic-pv-claim -n "$NAMESPACE" --ignore-not-found=true
		$KUBE_CLI_EXE delete pv mobiusview-presentation-storage mobiusview-diagnostic-pv-storage --ignore-not-found=true
		until ! $KUBE_CLI_EXE get pv mobiusview-presentation-storage >/dev/null 2>&1 && ! $KUBE_CLI_EXE get pv mobiusview-diagnostic-pv-storage >/dev/null 2>&1; do
			sleep 2
		done
	fi
}

install_mobiusview() {
	info_message "Installing mobius view"

	MOBIUSVIEW_STORAGE_FILE=mobiusview_storage.yaml;
  cp $kube_dir/mobiusview/storage/local/templates/$MOBIUSVIEW_STORAGE_FILE $kube_dir/mobiusview/storage/local/$MOBIUSVIEW_STORAGE_FILE;
	
	replace_tag_in_file $kube_dir/mobiusview/storage/local/$MOBIUSVIEW_STORAGE_FILE "<MOBIUSVIEW_DIAGNOSTIC_VOLUME>" $MOBIUSVIEW_DIAGNOSTIC_VOLUME;
	replace_tag_in_file $kube_dir/mobiusview/storage/local/$MOBIUSVIEW_STORAGE_FILE "<MOBIUSVIEW_PV_VOLUME>" $MOBIUSVIEW_PV_VOLUME;
	
	MOBIUSVIEW_VALUES_FILE=mobiusview.yaml;
  cp $kube_dir/mobiusview/templates/$MOBIUSVIEW_VALUES_FILE $kube_dir/mobiusview/$MOBIUSVIEW_VALUES_FILE;
	replace_tag_in_file $kube_dir/mobiusview/$MOBIUSVIEW_VALUES_FILE "<NAME_LOCALREGISTRY>" $NAME_LOCALREGISTRY;
	replace_tag_in_file $kube_dir/mobiusview/$MOBIUSVIEW_VALUES_FILE "<PORT_LOCALREGISTRY>" $PORT_LOCALREGISTRY;
	replace_tag_in_file $kube_dir/mobiusview/$MOBIUSVIEW_VALUES_FILE "<IMAGE_NAME_MOBIUSVIEW>" $IMAGE_NAME_MOBIUSVIEW;
	replace_tag_in_file $kube_dir/mobiusview/$MOBIUSVIEW_VALUES_FILE "<IMAGE_VERSION_MOBIUSVIEW>" $IMAGE_VERSION_MOBIUSVIEW;
	replace_tag_in_file $kube_dir/mobiusview/$MOBIUSVIEW_VALUES_FILE "<POSTGRESQL_USERNAME>" $POSTGRESQL_USERNAME;
	replace_tag_in_file $kube_dir/mobiusview/$MOBIUSVIEW_VALUES_FILE "<POSTGRESQL_PASSWORD>" $POSTGRESQL_PASSWORD;
	replace_tag_in_file $kube_dir/mobiusview/$MOBIUSVIEW_VALUES_FILE "<POSTGRESQL_HOST>" $POSTGRESQL_HOST;
	replace_tag_in_file $kube_dir/mobiusview/$MOBIUSVIEW_VALUES_FILE "<POSTGRESQL_PORT>" $POSTGRESQL_PORT;
	replace_tag_in_file $kube_dir/mobiusview/$MOBIUSVIEW_VALUES_FILE "<POSTGRESQL_DBNAME_MOBIUSVIEW>" $POSTGRESQL_DBNAME_MOBIUSVIEW;
	replace_tag_in_file $kube_dir/mobiusview/$MOBIUSVIEW_VALUES_FILE "<NAMESPACE>" $NAMESPACE;
	replace_tag_in_file $kube_dir/mobiusview/$MOBIUSVIEW_VALUES_FILE "<SMART_CHAT_ENABLED>" $SMART_CHAT_ENABLED;
  replace_tag_in_file $kube_dir/mobiusview/$MOBIUSVIEW_VALUES_FILE "<MOBIUSVIEW_SECURITY_JWT_PRIVATEKEY>" $MOBIUSVIEW_SECURITY_JWT_PRIVATEKEY;
  replace_tag_in_file $kube_dir/mobiusview/$MOBIUSVIEW_VALUES_FILE "<MOBIUSVIEW_SECURITY_JWT_PUBLICKEY>" $MOBIUSVIEW_SECURITY_JWT_PUBLICKEY;

	validate_mobius_shared_storage;
	reconcile_mobiusview_storage;

	if [ -n "${LICENSE_KEY:-}" ]; then
		MOBIUSVIEW_LICENSE_FILE=mobius-license.yaml;
		mkdir -p $kube_dir/mobiusview/secrets
		cp $kube_dir/mobiusview/secrets/templates/$MOBIUSVIEW_LICENSE_FILE $kube_dir/mobiusview/secrets/$MOBIUSVIEW_LICENSE_FILE;
		LICENSE_KEY=`echo -n $LICENSE_KEY | base64 -w 0`
		replace_tag_in_file $kube_dir/mobiusview/secrets/$MOBIUSVIEW_LICENSE_FILE "<MOBIUS_LICENSE>" $LICENSE_KEY;

		info_message "Applying secrets";
		$KUBE_CLI_EXE apply -f $kube_dir/mobiusview/secrets/$MOBIUSVIEW_LICENSE_FILE --namespace $NAMESPACE
	fi

  info_message "Creating mobiusview storage";
  $KUBE_CLI_EXE apply -f $kube_dir/mobiusview/storage/local/mobiusview_storage.yaml --namespace $NAMESPACE;
	
	info_message "Deploy mobiusview";
	helm upgrade mobiusview -n $NAMESPACE $kube_dir/helm_charts/mobiusview.tgz -f $kube_dir/mobiusview/mobiusview.yaml --install

	info_message "Clean up resources";
  rm -f $kube_dir/mobiusview/storage/local/$MOBIUSVIEW_STORAGE_FILE
  rm -f $kube_dir/mobiusview/$MOBIUSVIEW_VALUES_FILE
	if [ -n "${MOBIUSVIEW_LICENSE_FILE:-}" ]; then
		rm -f $kube_dir/mobiusview/secrets/$MOBIUSVIEW_LICENSE_FILE
	fi

}

wait_for_mobiusview_ready() {
    info_message "Waiting for mobiusview to be ready";
    COUNTER=0
	output=`kubectl get pods -n $NAMESPACE -o go-template --template '{{range .items}}{{if eq (.status.phase) ("Running")}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}'`
    until [[ "$output" == *mobiusview* ]]
    do
        info_progress "...";
		let COUNTER=COUNTER+5
		if [[ "$COUNTER" -gt 300 ]]; then
		  echo "FATAL: Failed to install mobiusview. Please check logs and configuration"
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

MOBIUSVIEW_PV_VOLUME=`eval echo ~/${NAMESPACE}_data/mobiusview/pv`
MOBIUSVIEW_DIAGNOSTIC_VOLUME=`eval echo ~/${NAMESPACE}_data/mobiusview/log`

install_mobiusview;
wait_for_mobiusview_ready;