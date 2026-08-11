#!/bin/bash
set -Eeuo pipefail


install_smart_chat() {
	info_message "Installing smart chat"	
	SMART_CHAT_VALUES_FILE=smart_chat.yaml;
	cp $kube_dir/smart_chat/templates/$SMART_CHAT_VALUES_FILE $kube_dir/smart_chat/$SMART_CHAT_VALUES_FILE;
	replace_tag_in_file $kube_dir/smart_chat/$SMART_CHAT_VALUES_FILE "<NAME_LOCALREGISTRY>" $NAME_LOCALREGISTRY;
	replace_tag_in_file $kube_dir/smart_chat/$SMART_CHAT_VALUES_FILE "<PORT_LOCALREGISTRY>" $PORT_LOCALREGISTRY;
	replace_tag_in_file $kube_dir/smart_chat/$SMART_CHAT_VALUES_FILE "<IMAGE_NAME_SMART_CHAT>" $IMAGE_NAME_SMART_CHAT;
	replace_tag_in_file $kube_dir/smart_chat/$SMART_CHAT_VALUES_FILE "<IMAGE_VERSION_SMART_CHAT>" $IMAGE_VERSION_SMART_CHAT;
	replace_tag_in_file $kube_dir/smart_chat/$SMART_CHAT_VALUES_FILE "<IMAGE_NAME_SMART_CHAT_QUERY_LOGS>" $IMAGE_NAME_SMART_CHAT_QUERY_LOGS;
	replace_tag_in_file $kube_dir/smart_chat/$SMART_CHAT_VALUES_FILE "<IMAGE_VERSION_SMART_CHAT_QUERY_LOGS>" $IMAGE_VERSION_SMART_CHAT_QUERY_LOGS;
	replace_tag_in_file $kube_dir/smart_chat/$SMART_CHAT_VALUES_FILE "<NAMESPACE>" $NAMESPACE;
	replace_tag_in_file $kube_dir/smart_chat/$SMART_CHAT_VALUES_FILE "<SMART_CHAT_INDEX>" $SMART_CHAT_INDEX;
	replace_tag_in_file $kube_dir/smart_chat/$SMART_CHAT_VALUES_FILE "<SMART_CHAT_QUERY_OPTIMIZATION>" $SMART_CHAT_QUERY_OPTIMIZATION;
	replace_tag_in_file $kube_dir/smart_chat/$SMART_CHAT_VALUES_FILE "<SMART_CHAT_QUERY_ROUTER_ENABLED>" $SMART_CHAT_QUERY_ROUTER_ENABLED;
	replace_tag_in_file $kube_dir/smart_chat/$SMART_CHAT_VALUES_FILE "<SMART_CHAT_WORKERS>" $SMART_CHAT_WORKERS;
	
	
	SMART_CHAT_SECRETS=smart-chat-secrets.yaml;
	cp $kube_dir/smart_chat/secrets/templates/$SMART_CHAT_SECRETS $kube_dir/smart_chat/secrets/$SMART_CHAT_SECRETS;
	OPENAI_API_KEY=`echo -n $OPENAI_API_KEY | base64 -w 0`
	replace_tag_in_file $kube_dir/smart_chat/secrets/$SMART_CHAT_SECRETS "<OPENAI_API_KEY>" $OPENAI_API_KEY;

	
	info_message "Applying secrets";
	if [ -n "$(ls $kube_dir/smart_chat/secrets/*.yaml 2>/dev/null)" ]; then 
	  $KUBE_CLI_EXE apply -f $kube_dir/smart_chat/secrets/$SMART_CHAT_SECRETS --namespace $NAMESPACE
	fi
	
	info_message "Deploy smart_chat"; 
	if [ -z $IMAGE_EXTRA_ARGS_SMART_CHAT]; then
	  helm upgrade smart-chat -n $NAMESPACE $kube_dir/helm_charts/smart-chat.tgz -f $kube_dir/smart_chat/$SMART_CHAT_VALUES_FILE --install
	else
	  helm upgrade smart-chat -n $NAMESPACE $kube_dir/helm_charts/smart-chat.tgz -f $kube_dir/smart_chat/$SMART_CHAT_VALUES_FILE $IMAGE_EXTRA_ARGS_SMART_CHAT --install
	fi
	
	
	info_message "Clean up resources";
	rm -f $kube_dir/smart_chat/$SMART_CHAT_VALUES_FILE
	rm -f $kube_dir/smart_chat/secrets/$SMART_CHAT_SECRETS
	

}

get_smart_chat_status() {
    $KUBE_CLI_EXE get pods --namespace $NAMESPACE smart_chat -o jsonpath="{.status.phase}" 2>/dev/null
}

wait_for_smart_chat_ready() {
    info_message "Waiting for smart-chat to be ready";
    COUNTER=0
	output=`kubectl get pods -n $NAMESPACE -o go-template --template '{{range .items}}{{if eq (.status.phase) ("Running")}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}'`
    until [[ "$output" == *smart-chat* ]]
    do
        info_progress "...";
		let COUNTER=COUNTER+5
		if [[ "$COUNTER" -gt 300 ]]; then
		  echo "FATAL: Failed to install smart_chat. Please check logs and configuration"
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

install_smart_chat;
wait_for_smart_chat_ready;
