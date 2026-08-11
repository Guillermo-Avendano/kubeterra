#!/bin/bash
set -Eeuo pipefail

install_studio() {

  STUDIO_STORAGE_FILE=studio_storage.yaml;
  cp $kube_dir/studio/storage/local/templates/$STUDIO_STORAGE_FILE $kube_dir/studio/storage/local/$STUDIO_STORAGE_FILE;
  replace_tag_in_file $kube_dir/studio/storage/local/$STUDIO_STORAGE_FILE "<STUDIO_PV_VOLUME>" $STUDIO_PV_VOLUME;

  STUDIO_VALUES_FILE=studio.yaml;
  cp $kube_dir/studio/templates/$STUDIO_VALUES_FILE $kube_dir/studio/$STUDIO_VALUES_FILE;
  replace_tag_in_file $kube_dir/studio/$STUDIO_VALUES_FILE "<NAME_LOCALREGISTRY>" $NAME_LOCALREGISTRY;
  replace_tag_in_file $kube_dir/studio/$STUDIO_VALUES_FILE "<PORT_LOCALREGISTRY>" $PORT_LOCALREGISTRY;
  replace_tag_in_file $kube_dir/studio/$STUDIO_VALUES_FILE "<IMAGE_NAME_STUDIO>" $IMAGE_NAME_STUDIO;
  replace_tag_in_file $kube_dir/studio/$STUDIO_VALUES_FILE "<IMAGE_VERSION_STUDIO>" $IMAGE_VERSION_STUDIO;
  replace_tag_in_file $kube_dir/studio/$STUDIO_VALUES_FILE "<POSTGRESQL_USERNAME>" $POSTGRESQL_USERNAME;
  replace_tag_in_file $kube_dir/studio/$STUDIO_VALUES_FILE "<POSTGRESQL_PASSWORD>" $POSTGRESQL_PASSWORD;
  replace_tag_in_file $kube_dir/studio/$STUDIO_VALUES_FILE "<POSTGRESQL_HOST>" $POSTGRESQL_HOST;
  replace_tag_in_file $kube_dir/studio/$STUDIO_VALUES_FILE "<POSTGRESQL_PORT>" $POSTGRESQL_PORT;
  replace_tag_in_file $kube_dir/studio/$STUDIO_VALUES_FILE "<POSTGRESQL_DBNAME_STUDIO>" $POSTGRESQL_DBNAME_STUDIO;
  replace_tag_in_file $kube_dir/studio/$STUDIO_VALUES_FILE "<NAMESPACE>" $NAMESPACE;
  replace_tag_in_file $kube_dir/studio/$STUDIO_VALUES_FILE "<MOBIUSVIEW_SECURITY_JWT_PRIVATEKEY>" $MOBIUSVIEW_SECURITY_JWT_PRIVATEKEY;
  replace_tag_in_file $kube_dir/studio/$STUDIO_VALUES_FILE "<MOBIUSVIEW_SECURITY_JWT_PUBLICKEY>" $MOBIUSVIEW_SECURITY_JWT_PUBLICKEY;
  replace_tag_in_file $kube_dir/studio/$STUDIO_VALUES_FILE "<OPTIONAL_DISPLAY_TEMPLATE_NAME>" $OPTIONAL_DISPLAY_TEMPLATE_NAME;
  replace_tag_in_file $kube_dir/studio/$STUDIO_VALUES_FILE "<MANDATORY_TEMPLATE_PATH>" $MANDATORY_TEMPLATE_PATH;

  info_message "Creating studio storage";
  $KUBE_CLI_EXE apply -f $kube_dir/studio/storage/local/studio_storage.yaml --namespace $NAMESPACE;

 info_message "Deploy studio";
 helm upgrade studio -n $NAMESPACE $kube_dir/helm_charts/studio.tgz -f $kube_dir/studio/studio.yaml --install

}

wait_for_studio_ready() {
    info_message "Waiting for studio to be ready";
    COUNTER=0
	output=`kubectl get pods -n $NAMESPACE -o go-template --template '{{range .items}}{{if eq (.status.phase) ("Running")}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}'`
    until [[ "$output" == *studio* ]]
    do
        info_progress "...";
		let COUNTER=COUNTER+5
		if [[ "$COUNTER" -gt 300 ]]; then
		  echo "FATAL: Failed to install studio. Please check logs and configuration"
          exit 1
		fi
        sleep 5;
		output=`kubectl get pods -n $NAMESPACE -o go-template --template '{{range .items}}{{if eq (.status.phase) ("Running")}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}'`
    done
}

sync_template_files() {
    info_message "Starting template file synchronization";

    TARGET_DIR="/home/asg/templates"

    APP_LABEL="app.kubernetes.io/name=studio"

    STUDIO_VALUES_PATH="$kube_dir/studio/studio.yaml"

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
			echo "Skip: Local file $CLEAN_PATH not found."
		fi
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
STUDIO_PV_VOLUME=`eval echo ~/${NAMESPACE}_data/studio/pv`
install_studio;
wait_for_studio_ready;
sync_template_files;

info_message "Clean up resources";
rm -f $kube_dir/studio/storage/local/$STUDIO_STORAGE_FILE
rm -f $kube_dir/studio/$STUDIO_VALUES_FILE
