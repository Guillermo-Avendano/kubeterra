#!/bin/bash
set -Eeuo pipefail

install_contentautomation() {

  PROCESS_STORAGE_FILE=process_storage.yaml;
  cp $kube_dir/contentautomation/storage/local/templates/$PROCESS_STORAGE_FILE $kube_dir/contentautomation/storage/local/$PROCESS_STORAGE_FILE;

  replace_tag_in_file $kube_dir/contentautomation/storage/local/$PROCESS_STORAGE_FILE "<PROCESS_PV_VOLUME>" $PROCESS_PV_VOLUME;

  APPAMANGER_STORAGE_FILE=appmanager_storage.yaml;
  cp $kube_dir/contentautomation/storage/local/templates/$APPAMANGER_STORAGE_FILE $kube_dir/contentautomation/storage/local/$APPAMANGER_STORAGE_FILE;

	replace_tag_in_file $kube_dir/contentautomation/storage/local/$APPAMANGER_STORAGE_FILE "<APPMANAGER_PV_VOLUME>" $APPMANAGER_PV_VOLUME;

  STUDIO_STORAGE_FILE=studio_storage.yaml;
  cp $kube_dir/contentautomation/storage/local/templates/$STUDIO_STORAGE_FILE $kube_dir/contentautomation/storage/local/$STUDIO_STORAGE_FILE;
  replace_tag_in_file $kube_dir/contentautomation/storage/local/$STUDIO_STORAGE_FILE "<STUDIO_PV_VOLUME>" $STUDIO_PV_VOLUME;

  CONTENTAUTOMATION_VALUES_FILE=contentautomation.yaml;
  cp $kube_dir/contentautomation/templates/$CONTENTAUTOMATION_VALUES_FILE $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE;
  replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<NAME_LOCALREGISTRY>" $NAME_LOCALREGISTRY;
	replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<PORT_LOCALREGISTRY>" $PORT_LOCALREGISTRY;
	replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<IMAGE_NAME_PROCESSENGINE>" $IMAGE_NAME_PROCESSENGINE;
	replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<IMAGE_VERSION_PROCESSENGINE>" $IMAGE_VERSION_PROCESSENGINE;
	replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<POSTGRESQL_USERNAME>" $POSTGRESQL_USERNAME;
	replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<POSTGRESQL_PASSWORD>" $POSTGRESQL_PASSWORD;
	replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<POSTGRESQL_HOST>" $POSTGRESQL_HOST;
	replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<POSTGRESQL_PORT>" $POSTGRESQL_PORT;
	replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<POSTGRESQL_DBNAME_PROCESSENGINE_FLOWABLE>" $POSTGRESQL_DBNAME_PROCESSENGINE_FLOWABLE;
	replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<POSTGRESQL_DBNAME_PROCESSENGINE_ROOT>" $POSTGRESQL_DBNAME_PROCESSENGINE_ROOT;
	replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<NAMESPACE>" $NAMESPACE;
  replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<MOBIUSVIEW_SECURITY_JWT_PRIVATEKEY>" $MOBIUSVIEW_SECURITY_JWT_PRIVATEKEY;
  replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<MOBIUSVIEW_SECURITY_JWT_PUBLICKEY>" $MOBIUSVIEW_SECURITY_JWT_PUBLICKEY;
  replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<PROCESS_MAIL_HOST>" $PROCESS_MAIL_HOST;
  replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<PROCESS_MAIL_FROM_EMAIL_ID>" $PROCESS_MAIL_FROM_EMAIL_ID;
  replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<PROCESS_MAIL_SERVER_USERNAME>" $PROCESS_MAIL_SERVER_USERNAME;
  replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<PROCESS_MAIL_SERVER_PASSWORD>" $PROCESS_MAIL_SERVER_PASSWORD;
  replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<PROCESSENGINE_LDAP_ENABLED>" $PROCESSENGINE_LDAP_ENABLED;
  replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<PROCESSENGINE_STORAGE_PATH>" $PROCESSENGINE_STORAGE_PATH;
  replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<PROCESSENGINE_TARGET_PATH>" $PROCESSENGINE_TARGET_PATH;
  replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<PROCESSENGINE_MOUNT_NAME>" $PROCESSENGINE_MOUNT_NAME;
  replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<AGENT_TASK_ENABLED>" $AGENT_TASK_ENABLED;

	replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<IMAGE_NAME_APPMANAGER>" $IMAGE_NAME_APPMANAGER;
	replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<IMAGE_VERSION_APPMANAGER>" $IMAGE_VERSION_APPMANAGER;
	replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<POSTGRESQL_DBNAME_APPMANAGER>" $POSTGRESQL_DBNAME_APPMANAGER;

  replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<IMAGE_NAME_STUDIO>" $IMAGE_NAME_STUDIO;
  replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<IMAGE_VERSION_STUDIO>" $IMAGE_VERSION_STUDIO;
  replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<POSTGRESQL_DBNAME_STUDIO>" $POSTGRESQL_DBNAME_STUDIO;

  if [[ -v OPTIONAL_DISPLAY_TEMPLATE_NAME && -n "$OPTIONAL_DISPLAY_TEMPLATE_NAME"  && -v MANDATORY_TEMPLATE_PATH  && -n "$MANDATORY_TEMPLATE_PATH" ]]; then
  replace_tag_in_file "$kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE" "<OPTIONAL_DISPLAY_TEMPLATE_NAME>" "$OPTIONAL_DISPLAY_TEMPLATE_NAME"
  replace_tag_in_file "$kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE" "<MANDATORY_TEMPLATE_PATH>" "$MANDATORY_TEMPLATE_PATH"
fi

    if [[ $AGENT_TASK_ENABLED == "true" ]]; then
    replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<OPENAI_API_KEY>" $OPENAI_API_KEY;
    replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<MCP_SERVER_NAME>" $MCP_SERVER_NAME;
    replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<MCP_SERVER_URL>" $MCP_SERVER_URL;
    replace_tag_in_file $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE "<MCP_SERVER_PATH>" $MCP_SERVER_PATH;
    fi

  info_message "Creating processengine storage";
  $KUBE_CLI_EXE apply -f $kube_dir/contentautomation/storage/local/process_storage.yaml --namespace $NAMESPACE;

  info_message "Creating appmanager storage";
  $KUBE_CLI_EXE apply -f $kube_dir/contentautomation/storage/local/appmanager_storage.yaml --namespace $NAMESPACE;

  info_message "Creating studio storage";
  $KUBE_CLI_EXE apply -f $kube_dir/contentautomation/storage/local/studio_storage.yaml --namespace $NAMESPACE;

  if [[ $PROCESSENGINE_LDAP_ENABLED == "true" ]]; then
        PROCESSENGINE_CUSTOMENV_FILE=processengine_customEnv.yaml;
        cp $kube_dir/contentautomation/templates/$PROCESSENGINE_CUSTOMENV_FILE $kube_dir/contentautomation/$PROCESSENGINE_CUSTOMENV_FILE;
        replace_tag_in_file $kube_dir/contentautomation/$PROCESSENGINE_CUSTOMENV_FILE "<NAMESPACE>" $NAMESPACE;
        replace_tag_in_file $kube_dir/contentautomation/$PROCESSENGINE_CUSTOMENV_FILE "<ASG_IAM_LDAP_ENABLED>" $PROCESSENGINE_LDAP_ENABLED;


        info_message "Applying processengine custom env";
        $KUBE_CLI_EXE apply -f $kube_dir/contentautomation/$PROCESSENGINE_CUSTOMENV_FILE --namespace $NAMESPACE;

        sleep 5;

        rm -f $kube_dir/contentautomation/$PROCESSENGINE_CUSTOMENV_FILE
    fi

  info_message "Deploy contentautomation";
  helm upgrade contentautomation -n $NAMESPACE $kube_dir/helm_charts/content-automation.tgz -f $kube_dir/contentautomation/contentautomation.yaml --install \
  --set deploymentMode=separate

}

wait_for_contentautomation_ready() {
    info_message "Waiting for contentautomation to be ready";
    COUNTER=0
	output=`kubectl get pods -n $NAMESPACE -o go-template --template '{{range .items}}{{if eq (.status.phase) ("Running")}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}'`
    until [[ "$output" == *contentautomation* ]]
    do
        info_progress "...";
		let COUNTER=COUNTER+5
		if [[ "$COUNTER" -gt 500 ]]; then
		  echo "FATAL: Failed to install contentautomation. Please check logs and configuration"
          exit 1
		fi
        sleep 5;
		output=`kubectl get pods -n $NAMESPACE -o go-template --template '{{range .items}}{{if eq (.status.phase) ("Running")}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}'`
    done
}


sync_template_files() {
    info_message "Starting template file synchronization";

    TARGET_DIR="/home/asg/templates"

    APP_LABEL="app.kubernetes.io/component=studio";

    STUDIO_VALUES_PATH="$kube_dir/contentautomation/contentautomation.yaml"

	POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l "$APP_LABEL" \
  -o jsonpath="{.items[*].metadata.name}" 2>/dev/null | awk '{print $1}' || true)
    if [ -z "$POD_NAME" ]; then
        echo "Warning: Could not find pod name for sync, skipping file copy."
        return
    fi

		PATHS=$(awk '
	  /templateLocalPath:/ {
		sub(/.*templateLocalPath:[[:space:]]*/, "", $0)
		gsub(/["\r]/, "", $0)
		print $0
	  }
	' "$STUDIO_VALUES_PATH" || true)

	if [ -z "$PATHS" ]; then
		info_message "No templatePath entries found, skipping sync."
		return
	fi
	for LOCAL_PATH in $PATHS; do
		CLEAN_PATH=$(echo "$LOCAL_PATH" | tr -d '\r' | tr '\\' '/' | sed 's/^\([A-Za-z]\):/\/\L\1/')
		FILENAME=$(basename "$CLEAN_PATH")

		if [ -f "/mnt/$CLEAN_PATH" ]; then
			echo "Uploading: $FILENAME"
			kubectl cp "/mnt/${CLEAN_PATH#*/}" "${NAMESPACE}/${POD_NAME}:${TARGET_DIR}/${FILENAME}"
		else
			echo "Skip: Local file $CLEAN_PATH not found or not configured."
		fi
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
APPMANAGER_PV_VOLUME=`eval echo ~/${NAMESPACE}_data/appmanager/pv`
PROCESS_PV_VOLUME=`eval echo ~/${NAMESPACE}_data/processengine/pv`
STUDIO_PV_VOLUME=`eval echo ~/${NAMESPACE}_data/studio/pv`

install_contentautomation;
post_processing;
wait_for_contentautomation_ready;
sync_template_files;

info_message "Clean up resources";
  rm -f $kube_dir/contentautomation/storage/local/$PROCESS_STORAGE_FILE
  rm -f $kube_dir/contentautomation/storage/local/$APPAMANGER_STORAGE_FILE
  rm -f $kube_dir/contentautomation/storage/local/$STUDIO_STORAGE_FILE
  rm -f $kube_dir/contentautomation/$CONTENTAUTOMATION_VALUES_FILE
