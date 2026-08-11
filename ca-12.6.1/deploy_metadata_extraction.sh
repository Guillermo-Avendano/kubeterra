#!/bin/bash
set -Eeuo pipefail

install_metadata_extraction() {
  METADATA_EXTRACTION_VALUES_FILE=metadata_extraction.yaml;
  cp $kube_dir/metadata_extraction/templates/$METADATA_EXTRACTION_VALUES_FILE $kube_dir/metadata_extraction/$METADATA_EXTRACTION_VALUES_FILE;
  replace_tag_in_file $kube_dir/metadata_extraction/$METADATA_EXTRACTION_VALUES_FILE "<NAME_LOCALREGISTRY>" $NAME_LOCALREGISTRY;
  replace_tag_in_file $kube_dir/metadata_extraction/$METADATA_EXTRACTION_VALUES_FILE "<PORT_LOCALREGISTRY>" $PORT_LOCALREGISTRY;
  replace_tag_in_file $kube_dir/metadata_extraction/$METADATA_EXTRACTION_VALUES_FILE "<IMAGE_NAME_METADATA_EXTRACTION>" $IMAGE_NAME_METADATA_EXTRACTION;
  replace_tag_in_file $kube_dir/metadata_extraction/$METADATA_EXTRACTION_VALUES_FILE "<NAMESPACE>" $NAMESPACE;
  replace_tag_in_file $kube_dir/metadata_extraction/$METADATA_EXTRACTION_VALUES_FILE "<IMAGE_VERSION_METADATA_EXTRACTION>" $IMAGE_VERSION_METADATA_EXTRACTION;

  METADATA_EXTRACTION_SECRETS=metadata-extraction-secrets.yaml;
  cp $kube_dir/metadata_extraction/secrets/templates/$METADATA_EXTRACTION_SECRETS $kube_dir/metadata_extraction/secrets/$METADATA_EXTRACTION_SECRETS;
	OPENAI_API_KEY=`echo -n $OPENAI_API_KEY | base64 -w 0`
	replace_tag_in_file $kube_dir/metadata_extraction/secrets/$METADATA_EXTRACTION_SECRETS "<OPENAI_API_KEY>" $OPENAI_API_KEY;


  info_message "Applying secrets";
	if [ -n "$(ls $kube_dir/metadata_extraction/secrets/*.yaml 2>/dev/null)" ]; then
  	$KUBE_CLI_EXE apply -f $kube_dir/metadata_extraction/secrets/$METADATA_EXTRACTION_SECRETS --namespace $NAMESPACE
  fi

  info_message "Deploy metadata_extraction";
  helm upgrade metadata-extraction -n $NAMESPACE $kube_dir/helm_charts/metadataextraction.tgz -f $kube_dir/metadata_extraction/metadata_extraction.yaml --install

  info_message "Clean up resources";
  rm -f $kube_dir/metadata_extraction/$METADATA_EXTRACTION_VALUES_FILE
}

wait_for_metadata_extraction_ready() {
    info_message "Waiting for metadata_extraction to be ready";
    COUNTER=0
	output=`kubectl get pods -n $NAMESPACE -o go-template --template '{{range .items}}{{if eq (.status.phase) ("Running")}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}'`
    until [[ "$output" == *metadata-extraction* ]]
    do
        info_progress "...";
		let COUNTER=COUNTER+5
		if [[ "$COUNTER" -gt 300 ]]; then
		  echo "FATAL: Failed to install metadata_extraction. Please check logs and configuration"
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

install_metadata_extraction;
wait_for_metadata_extraction_ready;