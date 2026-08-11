#!/bin/bash
set -Eeuo pipefail

reconcile_processengine_storage() {
  local reset_storage=false
  local phase=''
  local deleting=''

  phase=$($KUBE_CLI_EXE get pv process-pv-storage -o jsonpath='{.status.phase}' 2>/dev/null || true)
  if [ "$phase" == "Released" ]; then
    reset_storage=true
  fi

  if ! $KUBE_CLI_EXE get pvc process-pv-claim -n "$NAMESPACE" >/dev/null 2>&1; then
    reset_storage=true
  else
    deleting=$($KUBE_CLI_EXE get pvc process-pv-claim -n "$NAMESPACE" -o jsonpath='{.metadata.deletionTimestamp}' 2>/dev/null || true)
    if [ -n "$deleting" ]; then
      reset_storage=true
    fi
  fi

  if [ "$reset_storage" == "true" ]; then
    info_message "Resetting stale processengine storage resources";
    $KUBE_CLI_EXE delete pvc process-pv-claim -n "$NAMESPACE" --ignore-not-found=true
    $KUBE_CLI_EXE delete pv process-pv-storage --ignore-not-found=true
    until ! $KUBE_CLI_EXE get pv process-pv-storage >/dev/null 2>&1; do
      sleep 2
    done
  fi
}

install_processengine() {

  PROCESS_STORAGE_FILE=process_storage.yaml;
  cp $kube_dir/processengine/storage/local/templates/$PROCESS_STORAGE_FILE $kube_dir/processengine/storage/local/$PROCESS_STORAGE_FILE;

  replace_tag_in_file $kube_dir/processengine/storage/local/$PROCESS_STORAGE_FILE "<PROCESS_PV_VOLUME>" $PROCESS_PV_VOLUME;

  PROCESSENGINE_VALUES_FILE=processengine.yaml;
  cp $kube_dir/processengine/templates/$PROCESSENGINE_VALUES_FILE $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE;
  replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<NAME_LOCALREGISTRY>" $NAME_LOCALREGISTRY;
	replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<PORT_LOCALREGISTRY>" $PORT_LOCALREGISTRY;
	replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<IMAGE_NAME_PROCESSENGINE>" $IMAGE_NAME_PROCESSENGINE;
	replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<IMAGE_VERSION_PROCESSENGINE>" $IMAGE_VERSION_PROCESSENGINE;
	replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<POSTGRESQL_USERNAME>" $POSTGRESQL_USERNAME;
	replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<POSTGRESQL_PASSWORD>" $POSTGRESQL_PASSWORD;
	replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<POSTGRESQL_HOST>" $POSTGRESQL_HOST;
	replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<POSTGRESQL_PORT>" $POSTGRESQL_PORT;
	replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<POSTGRESQL_DBNAME_PROCESSENGINE_FLOWABLE>" $POSTGRESQL_DBNAME_PROCESSENGINE_FLOWABLE;
	replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<POSTGRESQL_DBNAME_PROCESSENGINE_ROOT>" $POSTGRESQL_DBNAME_PROCESSENGINE_ROOT;
	replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<NAMESPACE>" $NAMESPACE;
  replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<MOBIUSVIEW_SECURITY_JWT_PRIVATEKEY>" $MOBIUSVIEW_SECURITY_JWT_PRIVATEKEY;
  replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<MOBIUSVIEW_SECURITY_JWT_PUBLICKEY>" $MOBIUSVIEW_SECURITY_JWT_PUBLICKEY;
  replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<PROCESS_MAIL_HOST>" $PROCESS_MAIL_HOST;
  replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<PROCESS_MAIL_FROM_EMAIL_ID>" $PROCESS_MAIL_FROM_EMAIL_ID;
  replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<PROCESS_MAIL_SERVER_USERNAME>" $PROCESS_MAIL_SERVER_USERNAME;
  replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<PROCESS_MAIL_SERVER_PASSWORD>" $PROCESS_MAIL_SERVER_PASSWORD;
  replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<PROCESSENGINE_LDAP_ENABLED>" $PROCESSENGINE_LDAP_ENABLED;
  replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<PROCESSENGINE_STORAGE_PATH>" $PROCESSENGINE_STORAGE_PATH;
  replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<PROCESSENGINE_TARGET_PATH>" $PROCESSENGINE_TARGET_PATH;
  replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<PROCESSENGINE_MOUNT_NAME>" $PROCESSENGINE_MOUNT_NAME;
  replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<AGENT_TASK_ENABLED>" $AGENT_TASK_ENABLED;

    if [[ $AGENT_TASK_ENABLED == "true" ]]; then
    replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<OPENAI_API_KEY>" $OPENAI_API_KEY;
    replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<MCP_SERVER_NAME>" $MCP_SERVER_NAME;
    replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<MCP_SERVER_URL>" $MCP_SERVER_URL;
    replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE "<MCP_SERVER_PATH>" $MCP_SERVER_PATH;
    fi

  reconcile_processengine_storage;

  info_message "Creating processengine storage";
  $KUBE_CLI_EXE apply -f $kube_dir/processengine/storage/local/process_storage.yaml --namespace $NAMESPACE;

  if [[ $PROCESSENGINE_LDAP_ENABLED == "true" ]]; then
        PROCESSENGINE_CUSTOMENV_FILE=processengine_customEnv.yaml;
        cp $kube_dir/processengine/templates/$PROCESSENGINE_CUSTOMENV_FILE $kube_dir/processengine/$PROCESSENGINE_CUSTOMENV_FILE;
        replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_CUSTOMENV_FILE "<NAMESPACE>" $NAMESPACE;
        replace_tag_in_file $kube_dir/processengine/$PROCESSENGINE_CUSTOMENV_FILE "<ASG_IAM_LDAP_ENABLED>" $PROCESSENGINE_LDAP_ENABLED;


        info_message "Applying processengine custom env";
        $KUBE_CLI_EXE apply -f $kube_dir/processengine/$PROCESSENGINE_CUSTOMENV_FILE --namespace $NAMESPACE;

        sleep 5;

        rm -f $kube_dir/processengine/$PROCESSENGINE_CUSTOMENV_FILE
    fi

  info_message "Deploy processengine";
  helm upgrade processengine -n $NAMESPACE $kube_dir/helm_charts/processengine.tgz -f $kube_dir/processengine/processengine.yaml --install

  info_message "Clean up resources";
  rm -f $kube_dir/processengine/storage/local/$PROCESS_STORAGE_FILE
  rm -f $kube_dir/processengine/$PROCESSENGINE_VALUES_FILE
}

wait_for_processengine_ready() {
    info_message "Waiting for processengine to be ready";
    COUNTER=0
	output=`kubectl get pods -n $NAMESPACE -o go-template --template '{{range .items}}{{if eq (.status.phase) ("Running")}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}'`
    until [[ "$output" == *processengine* ]]
    do
        info_progress "...";
		let COUNTER=COUNTER+5
		if [[ "$COUNTER" -gt 300 ]]; then
		  echo "FATAL: Failed to install processengine. Please check logs and configuration"
          exit 1
		fi
        sleep 5;
		output=`kubectl get pods -n $NAMESPACE -o go-template --template '{{range .items}}{{if eq (.status.phase) ("Running")}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}'`
    done
}
post_processing() {
	if [[ $PROCESSENGINE_LDAP_ENABLED == "true" ]]; then
	  ENV_VARIABLES=" --from=configmap/processengine-custom-env "
	  $KUBE_CLI_EXE set env deployment.apps/processengine $ENV_VARIABLES -n $NAMESPACE
	fi
    sleep 20;
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
PROCESS_PV_VOLUME=`eval echo ~/${NAMESPACE}_data/processengine/pv`
install_processengine;
post_processing;
wait_for_processengine_ready;
