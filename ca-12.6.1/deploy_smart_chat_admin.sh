#!/bin/bash
set -Eeuo pipefail


ensure_smart_chat_admin_opensearch_ca_secret() {
	info_message "Ensuring smart-chat-admin OpenSearch CA secret"
	local temp_ca
	temp_ca=$(mktemp)
	kubectl -n "$NAMESPACE" exec statefulset/opensearch-cluster-master -- sh -lc 'cat /usr/share/opensearch/config/root-ca.pem' > "$temp_ca"
	kubectl -n "$NAMESPACE" create secret generic smart-chat--admin-certs \
		--from-file=root-ca.pem="$temp_ca" \
		--dry-run=client -o yaml | kubectl -n "$NAMESPACE" apply -f - >/dev/null
	rm -f "$temp_ca"
}


install_smart_chat_admin() {
	info_message "Installing smart chat admin"
	SMART_CHAT_ADMIN_VALUES_FILE=smart_chat_admin.yaml;
	cp $kube_dir/smart_chat_admin/templates/$SMART_CHAT_ADMIN_VALUES_FILE $kube_dir/smart_chat_admin/$SMART_CHAT_ADMIN_VALUES_FILE;

	replace_tag_in_file $kube_dir/smart_chat_admin/$SMART_CHAT_ADMIN_VALUES_FILE "<NAME_LOCALREGISTRY>" $NAME_LOCALREGISTRY;
	replace_tag_in_file $kube_dir/smart_chat_admin/$SMART_CHAT_ADMIN_VALUES_FILE "<PORT_LOCALREGISTRY>" $PORT_LOCALREGISTRY;
	replace_tag_in_file $kube_dir/smart_chat_admin/$SMART_CHAT_ADMIN_VALUES_FILE "<IMAGE_NAME_SMART_CHAT_ADMIN>" $IMAGE_NAME_SMART_CHAT_ADMIN;
	replace_tag_in_file $kube_dir/smart_chat_admin/$SMART_CHAT_ADMIN_VALUES_FILE "<IMAGE_VERSION_SMART_CHAT_ADMIN>" $IMAGE_VERSION_SMART_CHAT_ADMIN;
	replace_tag_in_file $kube_dir/smart_chat_admin/$SMART_CHAT_ADMIN_VALUES_FILE "<NAMESPACE>" $NAMESPACE;
	replace_tag_in_file $kube_dir/smart_chat_admin/$SMART_CHAT_ADMIN_VALUES_FILE "<OPENSEARCH_SERVICE_IP>" "$(kubectl -n "$NAMESPACE" get svc opensearch-cluster-master -o jsonpath='{.spec.clusterIP}')";
	# Iterate over all SMARTCHAT_CONSOLE_ADMIN{n}_USERNAME/PASSWORD vars and inject into adminUsers list.
	# Stops at the first index where username is missing or empty. Skips entry if either value is empty.
	local i=1
	while true; do
		local admin_user_var="SMARTCHAT_CONSOLE_ADMIN${i}_USERNAME"
		local admin_pass_var="SMARTCHAT_CONSOLE_ADMIN${i}_PASSWORD"
		local admin_user="${!admin_user_var:-}"
		local admin_pass="${!admin_pass_var:-}"
		[ -n "$admin_user" ] || break
		if [ -n "$admin_pass" ]; then
			sed -i'' "s/<ADMIN_USERS_LIST>/  - username: \"${admin_user}\"\n    password: \"${admin_pass}\"\n<ADMIN_USERS_LIST>/" \
				$kube_dir/smart_chat_admin/$SMART_CHAT_ADMIN_VALUES_FILE
		fi
		i=$((i + 1))
	done
	sed -i'' 's/<ADMIN_USERS_LIST>//' $kube_dir/smart_chat_admin/$SMART_CHAT_ADMIN_VALUES_FILE

	# Iterate over all SMARTCHAT_CONSOLE_USER{n}_USERNAME/PASSWORD vars and inject into regularUsers list.
	# Stops at the first index where username is missing or empty. Skips entry if either value is empty.
	i=1
	while true; do
		local user_user_var="SMARTCHAT_CONSOLE_USER${i}_USERNAME"
		local user_pass_var="SMARTCHAT_CONSOLE_USER${i}_PASSWORD"
		local user_user="${!user_user_var:-}"
		local user_pass="${!user_pass_var:-}"
		[ -n "$user_user" ] || break
		if [ -n "$user_pass" ]; then
			sed -i'' "s/<REGULAR_USERS_LIST>/  - username: \"${user_user}\"\n    password: \"${user_pass}\"\n<REGULAR_USERS_LIST>/" \
				$kube_dir/smart_chat_admin/$SMART_CHAT_ADMIN_VALUES_FILE
		fi
		i=$((i + 1))
	done
	sed -i'' 's/<REGULAR_USERS_LIST>//' $kube_dir/smart_chat_admin/$SMART_CHAT_ADMIN_VALUES_FILE

	ensure_smart_chat_admin_opensearch_ca_secret

	info_message "Deploy smart_chat_admin";
	local smart_chat_admin_chart="$kube_dir/helm_charts/smart-chat-admin"
	if [ ! -d "$smart_chat_admin_chart" ]; then
		smart_chat_admin_chart="$kube_dir/helm_charts/smart-chat-admin.tgz"
	fi
	if [ -z "$IMAGE_EXTRA_ARGS_SMART_CHAT_ADMIN" ]; then
	  helm upgrade smart-chat-admin -n $NAMESPACE "$smart_chat_admin_chart" -f $kube_dir/smart_chat_admin/$SMART_CHAT_ADMIN_VALUES_FILE --install
	else
	  helm upgrade smart-chat-admin -n $NAMESPACE "$smart_chat_admin_chart" -f $kube_dir/smart_chat_admin/$SMART_CHAT_ADMIN_VALUES_FILE $IMAGE_EXTRA_ARGS_SMART_CHAT_ADMIN --install
	fi

	info_message "Clean up resources";
	rm -f $kube_dir/smart_chat_admin/$SMART_CHAT_ADMIN_VALUES_FILE
}

wait_for_smart_chat_admin_ready() {
    info_message "Waiting for smart-chat-admin to be ready";
    COUNTER=0
	output=`kubectl get pods -n $NAMESPACE -o go-template --template '{{range .items}}{{if eq (.status.phase) ("Running")}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}'`
    until [[ "$output" == *smart-chat-admin* ]]
    do
        info_progress "...";
		let COUNTER=COUNTER+5
		if [[ "$COUNTER" -gt 300 ]]; then
		  echo "FATAL: Failed to install smart_chat_admin. Please check logs and configuration"
          exit 1
		fi
        sleep 5;
		output=`kubectl get pods -n $NAMESPACE -o go-template --template '{{range .items}}{{if eq (.status.phase) ("Running")}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}'`
    done
}


xargsflag="-d"
kube_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
[ -d "$kube_dir" ] || {
  echo "FATAL: no current dir (maybe running in zsh?)"
  exit 1
}

set -a
# shellcheck disable=SC1091
source "$kube_dir/.env"
set +a

source "$kube_dir/common/common.sh"
source "$kube_dir/common/local_kube.sh"

kube_init;

install_smart_chat_admin;
wait_for_smart_chat_admin_ready;