#!/bin/bash
set -Eeuo pipefail

install_classification() {
  CLASSIFICATION_VALUES_FILE=smart_classification.yaml;
  cp $kube_dir/smart_classification/templates/$CLASSIFICATION_VALUES_FILE $kube_dir/smart_classification/$CLASSIFICATION_VALUES_FILE;
  replace_tag_in_file $kube_dir/smart_classification/$CLASSIFICATION_VALUES_FILE "<NAME_LOCALREGISTRY>" $NAME_LOCALREGISTRY;
  replace_tag_in_file $kube_dir/smart_classification/$CLASSIFICATION_VALUES_FILE "<PORT_LOCALREGISTRY>" $PORT_LOCALREGISTRY;
  replace_tag_in_file $kube_dir/smart_classification/$CLASSIFICATION_VALUES_FILE "<POSTGRESQL_HOST>" $POSTGRESQL_HOST;
  replace_tag_in_file $kube_dir/smart_classification/$CLASSIFICATION_VALUES_FILE "<POSTGRESQL_PORT>" $POSTGRESQL_PORT;
  replace_tag_in_file $kube_dir/smart_classification/$CLASSIFICATION_VALUES_FILE "<POSTGRESQL_DBNAME_SMART_CLASSIFICATION>" $POSTGRESQL_DBNAME_SMART_CLASSIFICATION;
  replace_tag_in_file $kube_dir/smart_classification/$CLASSIFICATION_VALUES_FILE "<IMAGE_VERSION_SMART_CLASSIFICATION>" $IMAGE_VERSION_SMART_CLASSIFICATION;
  replace_tag_in_file $kube_dir/smart_classification/$CLASSIFICATION_VALUES_FILE "<IMAGE_NAME_SMART_CLASSIFICATION>" $IMAGE_NAME_SMART_CLASSIFICATION;
  replace_tag_in_file $kube_dir/smart_classification/$CLASSIFICATION_VALUES_FILE "<NAMESPACE>" $NAMESPACE;

  CLASSIFICATION_SECRETS=smart_classification_secrets.yaml;
  cp $kube_dir/smart_classification/secrets/templates/$CLASSIFICATION_SECRETS $kube_dir/smart_classification/secrets/$CLASSIFICATION_SECRETS;
	OPENAI_API_KEY=`echo -n $OPENAI_API_KEY | base64 -w 0`
	POSTGRESQL_USERNAME=`echo -n $POSTGRESQL_USERNAME | base64 -w 0`
	POSTGRESQL_PASSWORD=`echo -n $POSTGRESQL_PASSWORD | base64 -w 0`
	replace_tag_in_file $kube_dir/smart_classification/secrets/$CLASSIFICATION_SECRETS "<OPENAI_API_KEY>" $OPENAI_API_KEY;
	replace_tag_in_file $kube_dir/smart_classification/secrets/$CLASSIFICATION_SECRETS "<POSTGRESQL_USERNAME>" $POSTGRESQL_USERNAME;
	replace_tag_in_file $kube_dir/smart_classification/secrets/$CLASSIFICATION_SECRETS "<POSTGRESQL_PASSWORD>" $POSTGRESQL_PASSWORD;


  info_message "Applying secrets";
	if [ -n "$(ls $kube_dir/smart_classification/secrets/*.yaml 2>/dev/null)" ]; then
  	$KUBE_CLI_EXE apply -f $kube_dir/smart_classification/secrets/$CLASSIFICATION_SECRETS --namespace $NAMESPACE

  replace_tag_in_file $kube_dir/smart_classification/$CLASSIFICATION_VALUES_FILE "<CLASSIFICATION_SECRET>" $CLASSIFICATION_SECRET;
  fi

  info_message "Deploy smart_classification";
  helm upgrade smart-classification -n $NAMESPACE $kube_dir/helm_charts/smart-classification.tgz -f $kube_dir/smart_classification/smart_classification.yaml --install

  info_message "Clean up resources";
  rm -f $kube_dir/smart_classification/$CLASSIFICATION_VALUES_FILE
  rm -f $kube_dir/smart_classification/$CLASSIFICATION_SECRETS
  }

wait_for_classification_ready() {
    info_message "Waiting for smart_classification to be ready";
    COUNTER=0
	output=`kubectl get pods -n $NAMESPACE -o go-template --template '{{range .items}}{{if eq (.status.phase) ("Running")}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}'`
    until [[ "$output" == *smart-classification* ]]
    do
        info_progress "...";
		let COUNTER=COUNTER+5
		if [[ "$COUNTER" -gt 300 ]]; then
		  echo "FATAL: Failed to install smart_classification. Please check logs and configuration"
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
CLASSIFICATION_SECRET=smart_classification_secrets

kube_init;

install_classification;
wait_for_classification_ready;


#IMAGE_NAME_SMART_CLASSIFICATION=smart-classification
#IMAGE_VERSION_SMART_CLASSIFICATION=1.0.0-SNAPSHOT
#POSTGRESQL_DBNAME_SMART_CLASSIFICATION=model_backups
# SMART_CLASSIFICATION_DOCKER_REGISTRY=registry.rocketsoftware.com
