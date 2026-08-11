#!/bin/bash
set -Eeuo pipefail


install_smart_chat_indexing_proxy() {
	info_message "Installing smart chat indexing proxy"	
	SMART_CHAT_INDEXING_PROXY_VALUES_FILE=smart_chat_indexing_proxy.yaml;
	cp $kube_dir/smart_chat_indexing_proxy/templates/$SMART_CHAT_INDEXING_PROXY_VALUES_FILE $kube_dir/smart_chat_indexing_proxy/$SMART_CHAT_INDEXING_PROXY_VALUES_FILE;
	replace_tag_in_file $kube_dir/smart_chat_indexing_proxy/$SMART_CHAT_INDEXING_PROXY_VALUES_FILE "<NAME_LOCALREGISTRY>" $NAME_LOCALREGISTRY;
	replace_tag_in_file $kube_dir/smart_chat_indexing_proxy/$SMART_CHAT_INDEXING_PROXY_VALUES_FILE "<PORT_LOCALREGISTRY>" $PORT_LOCALREGISTRY;
	replace_tag_in_file $kube_dir/smart_chat_indexing_proxy/$SMART_CHAT_INDEXING_PROXY_VALUES_FILE "<IMAGE_NAME_SMART_CHAT_INDEXING_PROXY>" $IMAGE_NAME_SMART_CHAT_INDEXING_PROXY;
	replace_tag_in_file $kube_dir/smart_chat_indexing_proxy/$SMART_CHAT_INDEXING_PROXY_VALUES_FILE "<IMAGE_VERSION_SMART_CHAT_INDEXING_PROXY>" $IMAGE_VERSION_SMART_CHAT_INDEXING_PROXY;
	replace_tag_in_file $kube_dir/smart_chat_indexing_proxy/$SMART_CHAT_INDEXING_PROXY_VALUES_FILE "<NAMESPACE>" $NAMESPACE;
	
	
	info_message "Deploy smart_chat_indexing_proxy"; 
	if [ -z $IMAGE_EXTRA_ARGS_SMART_CHAT_INDEXING_PROXY]; then
	  helm upgrade smart-chat-indexing-proxy -n $NAMESPACE $kube_dir/helm_charts/smart-chat-indexing-proxy.tgz -f $kube_dir/smart_chat_indexing_proxy/$SMART_CHAT_INDEXING_PROXY_VALUES_FILE --install
	else
	  helm upgrade smart-chat-indexing-proxy -n $NAMESPACE $kube_dir/helm_charts/smart-chat-indexing-proxy.tgz -f $kube_dir/smart_chat_indexing_proxy/$SMART_CHAT_INDEXING_PROXY_VALUES_FILE $IMAGE_EXTRA_ARGS_SMART_CHAT_INDEXING_PROXY --install
	fi
	
	
	info_message "Clean up resources";
	rm -f $kube_dir/smart_chat_indexing_proxy/$SMART_CHAT_INDEXING_PROXY_VALUES_FILE

}

get_smart_chat_indexing_proxy_status() {
    $KUBE_CLI_EXE get pods --namespace $NAMESPACE smart_chat_indexing_proxy -o jsonpath="{.status.phase}" 2>/dev/null
}

wait_for_smart_chat_indexing_proxy_ready() {
    info_message "Waiting for smart_chat_indexing_proxy to be ready";
    COUNTER=0
	output=`kubectl get pods -n $NAMESPACE -o go-template --template '{{range .items}}{{if eq (.status.phase) ("Running")}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}'`
    until [[ "$output" == *smart-chat-indexing-proxy* ]]
    do
        info_progress "...";
		let COUNTER=COUNTER+5
		if [[ "$COUNTER" -gt 300 ]]; then
		  echo "FATAL: Failed to install smart-chat indexingproxy. Please check logs and configuration"
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

install_smart_chat_indexing_proxy;
wait_for_smart_chat_indexing_proxy_ready;
