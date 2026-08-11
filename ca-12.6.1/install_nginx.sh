#!/bin/bash
set -Eeuo pipefail

install_nginx() {
	create_kubernetes_namespace $NGINX_NAMESPACE;
	
	info_message "Configuring nginx $NGINX_VERSION resources";
				
  cp $kube_dir/nginx/templates/$NGINX_CONF_FILE $kube_dir/nginx/$NGINX_CONF_FILE;
  replace_tag_in_file $kube_dir/nginx/$NGINX_CONF_FILE "<NGINX_VERSION>" $NGINX_VERSION;
	replace_tag_in_file $kube_dir/nginx/$NGINX_CONF_FILE "<NAMESPACE>" $NAMESPACE;
	
	cp $kube_dir/nginx/templates/$NGINX_CUSTOM_SET_HEADER_FILE $kube_dir/nginx/$NGINX_CUSTOM_SET_HEADER_FILE;
  replace_tag_in_file $kube_dir/nginx/$NGINX_CUSTOM_SET_HEADER_FILE "<NGINX_NAMESPACE>" $NGINX_NAMESPACE;

  cp $kube_dir/nginx/templates/$NGINX_CUSTOM_ADD_HEADER_FILE $kube_dir/nginx/$NGINX_CUSTOM_ADD_HEADER_FILE;
  replace_tag_in_file $kube_dir/nginx/$NGINX_CUSTOM_ADD_HEADER_FILE "<NGINX_NAMESPACE>" $NGINX_NAMESPACE;
	
	cp $kube_dir/nginx/templates/$NGINX_CUSTOM_CONF_FILE $kube_dir/nginx/$NGINX_CUSTOM_CONF_FILE;
  replace_tag_in_file $kube_dir/nginx/$NGINX_CUSTOM_CONF_FILE "<NGINX_NAMESPACE>" $NGINX_NAMESPACE;

	cp $kube_dir/nginx/templates/$NGINX_CUSTOM_CONFIG_FILE $kube_dir/nginx/$NGINX_CUSTOM_CONFIG_FILE;
  replace_tag_in_file $kube_dir/nginx/$NGINX_CUSTOM_CONFIG_FILE "<NGINX_NAMESPACE>" $NGINX_NAMESPACE;

	cp $kube_dir/nginx/templates/$NGINX_MOBIUSVIEW_INGRESS_FILE $kube_dir/nginx/$NGINX_MOBIUSVIEW_INGRESS_FILE;
	replace_tag_in_file $kube_dir/nginx/$NGINX_MOBIUSVIEW_INGRESS_FILE "<NAMESPACE>" $NAMESPACE;
  replace_tag_in_file $kube_dir/nginx/$NGINX_MOBIUSVIEW_INGRESS_FILE "<HOSTNAME>" $HOSTNAME;

	cp $kube_dir/nginx/templates/$NGINX_APPMANAGER_INGRESS_FILE $kube_dir/nginx/$NGINX_APPMANAGER_INGRESS_FILE;
  replace_tag_in_file $kube_dir/nginx/$NGINX_APPMANAGER_INGRESS_FILE "<NAMESPACE>" $NAMESPACE;
  replace_tag_in_file $kube_dir/nginx/$NGINX_APPMANAGER_INGRESS_FILE "<HOSTNAME>" $HOSTNAME;

  cp $kube_dir/nginx/templates/$NGINX_PROCESSENGINE_INGRESS_FILE $kube_dir/nginx/$NGINX_PROCESSENGINE_INGRESS_FILE;
  replace_tag_in_file $kube_dir/nginx/$NGINX_PROCESSENGINE_INGRESS_FILE "<NAMESPACE>" $NAMESPACE;
  replace_tag_in_file $kube_dir/nginx/$NGINX_PROCESSENGINE_INGRESS_FILE "<HOSTNAME>" $HOSTNAME;

  cp $kube_dir/nginx/templates/$NGINX_STUDIO_INGRESS_FILE $kube_dir/nginx/$NGINX_STUDIO_INGRESS_FILE;
  replace_tag_in_file $kube_dir/nginx/$NGINX_STUDIO_INGRESS_FILE "<NAMESPACE>" $NAMESPACE;
  replace_tag_in_file $kube_dir/nginx/$NGINX_STUDIO_INGRESS_FILE "<HOSTNAME>" $HOSTNAME;

  cp $kube_dir/nginx/templates/$NGINX_APPAMANGER_AUTH_INGRESS_FILE $kube_dir/nginx/$NGINX_APPAMANGER_AUTH_INGRESS_FILE;
  replace_tag_in_file $kube_dir/nginx/$NGINX_APPAMANGER_AUTH_INGRESS_FILE "<NAMESPACE>" $NAMESPACE;
  replace_tag_in_file $kube_dir/nginx/$NGINX_APPAMANGER_AUTH_INGRESS_FILE "<HOSTNAME>" $HOSTNAME;

  cp $kube_dir/nginx/templates/$NGINX_METADATA_EXTRACTION_INGRESS_FILE $kube_dir/nginx/$NGINX_METADATA_EXTRACTION_INGRESS_FILE;
  replace_tag_in_file $kube_dir/nginx/$NGINX_METADATA_EXTRACTION_INGRESS_FILE "<NAMESPACE>" $NAMESPACE;
  replace_tag_in_file $kube_dir/nginx/$NGINX_METADATA_EXTRACTION_INGRESS_FILE "<HOSTNAME>" $HOSTNAME;

  cp $kube_dir/nginx/templates/$NGINX_SMART_CLASSIFICATION_INGRESS_FILE $kube_dir/nginx/$NGINX_SMART_CLASSIFICATION_INGRESS_FILE;
  replace_tag_in_file $kube_dir/nginx/$NGINX_SMART_CLASSIFICATION_INGRESS_FILE "<NAMESPACE>" $NAMESPACE;
  replace_tag_in_file $kube_dir/nginx/$NGINX_SMART_CLASSIFICATION_INGRESS_FILE "<HOSTNAME>" $HOSTNAME;

  cp $kube_dir/nginx/templates/$NGINX_CONTENTAUTOMATION_INGRESS_FILE $kube_dir/nginx/$NGINX_CONTENTAUTOMATION_INGRESS_FILE;
  replace_tag_in_file $kube_dir/nginx/$NGINX_CONTENTAUTOMATION_INGRESS_FILE "<NAMESPACE>" $NAMESPACE;
  replace_tag_in_file $kube_dir/nginx/$NGINX_CONTENTAUTOMATION_INGRESS_FILE "<HOSTNAME>" $HOSTNAME;

  cp $kube_dir/nginx/templates/$NGINX_MOBIUS_CONTENTAUTOMATION_PROCESS_INGRESS_FILE $kube_dir/nginx/$NGINX_MOBIUS_CONTENTAUTOMATION_PROCESS_INGRESS_FILE;
  replace_tag_in_file $kube_dir/nginx/$NGINX_MOBIUS_CONTENTAUTOMATION_PROCESS_INGRESS_FILE "<NAMESPACE>" $NAMESPACE;
  replace_tag_in_file $kube_dir/nginx/$NGINX_MOBIUS_CONTENTAUTOMATION_PROCESS_INGRESS_FILE "<HOSTNAME>" $HOSTNAME;

	helm repo add ingress-nginx  https://kubernetes.github.io/ingress-nginx
	helm repo update


	CERT_NAME=nginx-cert
  CERT_FILE=$kube_dir/nginx/nginx.cert
  KEY_FILE=$kube_dir/nginx/nginx.key
  CA_CERT_FILE=$kube_dir/nginx/ca.crt
  CA_KEY_FILE=$kube_dir/nginx/ca.key
  CSR_FILE=$kube_dir/nginx/nginx.csr
  CA_CNF_FILE=$kube_dir/nginx/ca.cnf
  BASIC_AUTH_CERT_NAME=basic-auth

  exists=$(check_if_kubernetes_resource_exists secret ${CERT_NAME} $NAMESPACE);

    if [ "$exists" == "true" ]; then
        info_message "Using existing secret for certificates"
    else
	  if [[ ! -f "${CERT_FILE}" || ! -f "${KEY_FILE}" ]] ; then
	    if [[ -f "${CA_CERT_FILE}" && -f "${CA_KEY_FILE}" ]] ; then
	      info_message "Generating server certificate signed by CA";
	      openssl req -new -newkey rsa:2048 -keyout ${KEY_FILE} -out ${CSR_FILE} -subj "/CN=$HOSTNAME" -addext "subjectAltName=DNS:$HOSTNAME" -nodes;
	      openssl x509 -req -in ${CSR_FILE} -CA ${CA_CERT_FILE} -CAkey ${CA_KEY_FILE} -CAcreateserial -out ${CERT_FILE} -days 365 -copy_extensions copyall;
	      rm -f ${CSR_FILE};
	    else
	      info_message "Creating self signed certificate";
	      openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${KEY_FILE} -out ${CERT_FILE} -subj "/CN=$HOSTNAME/O=$HOSTNAME" -addext "subjectAltName = DNS:$HOSTNAME";
	    fi
      else
        info_message "Using existing certificates for secret";
      fi

  	  info_message "Creating secret";
	  $KUBE_CLI_EXE create secret tls ${CERT_NAME} --key ${KEY_FILE} --cert ${CERT_FILE} -n $NAMESPACE

    fi

     basic_auth_exists=$(check_if_kubernetes_resource_exists secret ${BASIC_AUTH_CERT_NAME} $NAMESPACE);
    if [ "$basic_auth_exists" == "true" ]; then
        info_message "Using existing secret for basic-auth "
    else
         info_message "Creating basic-auth";
          $KUBE_CLI_EXE create secret generic basic-auth --from-file=$kube_dir/nginx/auth -n $NAMESPACE
    fi

	info_message "Installing nginx $NGINX_VERSION";
    helm upgrade nginx ingress-nginx/ingress-nginx -f $kube_dir/nginx/$NGINX_CONF_FILE -n $NGINX_NAMESPACE --install

	info_message "Waiting for nginx to be ready";
  sleep 30

	info_message "Applying custom configuration"
	$KUBE_CLI_EXE apply -f  $kube_dir/nginx/$NGINX_CUSTOM_ADD_HEADER_FILE --namespace $NGINX_NAMESPACE
	$KUBE_CLI_EXE apply -f  $kube_dir/nginx/$NGINX_CUSTOM_SET_HEADER_FILE --namespace $NGINX_NAMESPACE
	$KUBE_CLI_EXE apply -f  $kube_dir/nginx/$NGINX_CUSTOM_CONF_FILE --namespace $NGINX_NAMESPACE
	$KUBE_CLI_EXE apply -f  $kube_dir/nginx/$NGINX_CUSTOM_CONFIG_FILE --namespace $NGINX_NAMESPACE
	sleep 30

	info_message "Configuring nginx rules"
	$KUBE_CLI_EXE apply -f  $kube_dir/nginx/$NGINX_MOBIUSVIEW_INGRESS_FILE --namespace $NAMESPACE
  $KUBE_CLI_EXE apply -f  $kube_dir/nginx/$NGINX_APPMANAGER_INGRESS_FILE --namespace $NAMESPACE
  $KUBE_CLI_EXE apply -f  $kube_dir/nginx/$NGINX_PROCESSENGINE_INGRESS_FILE --namespace $NAMESPACE
  $KUBE_CLI_EXE apply -f  $kube_dir/nginx/$NGINX_STUDIO_INGRESS_FILE --namespace $NAMESPACE
  $KUBE_CLI_EXE apply -f  $kube_dir/nginx/$NGINX_APPAMANGER_AUTH_INGRESS_FILE --namespace $NAMESPACE
  $KUBE_CLI_EXE apply -f  $kube_dir/nginx/$NGINX_METADATA_EXTRACTION_INGRESS_FILE --namespace $NAMESPACE
  $KUBE_CLI_EXE apply -f  $kube_dir/nginx/$NGINX_CONTENTAUTOMATION_INGRESS_FILE --namespace $NAMESPACE
  $KUBE_CLI_EXE apply -f  $kube_dir/nginx/$NGINX_MOBIUS_CONTENTAUTOMATION_PROCESS_INGRESS_FILE --namespace $NAMESPACE
  #$KUBE_CLI_EXE apply -f  $kube_dir/nginx/$NGINX_SMART_CLASSIFICATION_INGRESS_FILE --namespace $NAMESPACE

	#info_message "Clean up resources";
  rm -f $kube_dir/nginx/$NGINX_CONF_FILE
  rm -f $kube_dir/nginx/$NGINX_CUSTOM_CONFIG_FILE
	rm -f $kube_dir/nginx/$NGINX_CUSTOM_CONF_FILE
	rm -f $kube_dir/nginx/$NGINX_CUSTOM_ADD_HEADER_FILE
	rm -f $kube_dir/nginx/$NGINX_CUSTOM_SET_HEADER_FILE
  rm -f $kube_dir/nginx/$NGINX_MOBIUSVIEW_INGRESS_FILE
  rm -f $kube_dir/nginx/$NGINX_APPMANAGER_INGRESS_FILE
  rm -f $kube_dir/nginx/$NGINX_PROCESSENGINE_INGRESS_FILE
  rm -f $kube_dir/nginx/$NGINX_STUDIO_INGRESS_FILE
  rm -f $kube_dir/nginx/$NGINX_APPAMANGER_AUTH_INGRESS_FILE
  rm -f $kube_dir/nginx/$NGINX_METADATA_EXTRACTION_INGRESS_FILE
  rm -f $kube_dir/nginx/$NGINX_CONTENTAUTOMATION_INGRESS_FILE
  rm -f $kube_dir/nginx/$NGINX_MOBIUS_CONTENTAUTOMATION_PROCESS_INGRESS_FILE
  rm -f $kube_dir/nginx/$NGINX_SMART_CLASSIFICATION_INGRESS_FILE

  sleep 10

    #Uncomment if k3d portforwaring doesn't work and make NGINX a nodeport service.
	#info_message "Forward a local port to the TLS port of ingress controller"
	#$KUBE_CLI_EXE port-forward --address 0.0.0.0 --namespace=$NGINX_NAMESPACE service/nginx-ingress-nginx-controller $NGINX_EXTERNAL_TLS_PORT:443 >/dev/null 2>&1 &
}

install_smart_chat_admin_nginx_ingress() {

  cp $kube_dir/nginx/templates/$SMART_CHAT_ADMIN_NGINX_INGRESS_FILE $kube_dir/smart_chat_admin/$SMART_CHAT_ADMIN_NGINX_INGRESS_FILE;
        replace_tag_in_file $kube_dir/smart_chat_admin/$SMART_CHAT_ADMIN_NGINX_INGRESS_FILE "<NAMESPACE>" $NAMESPACE;
    replace_tag_in_file $kube_dir/smart_chat_admin/$SMART_CHAT_ADMIN_NGINX_INGRESS_FILE "<HOSTNAME>" $HOSTNAME;

        info_message "Configuring smart-chat-admin nginx rules"

        sleep 30

        $KUBE_CLI_EXE apply -f  $kube_dir/smart_chat_admin/$SMART_CHAT_ADMIN_NGINX_INGRESS_FILE --namespace $NAMESPACE

        #info_message "Clean up resources";
    rm -f $kube_dir/smart_chat_admin/$SMART_CHAT_ADMIN_NGINX_INGRESS_FILE
    sleep 10
}
wait_for_nginx_ready() {
    info_message "Waiting for nginx to be ready";
    COUNTER=0
	output=`kubectl get pods -n $NGINX_NAMESPACE -o go-template --template '{{range .items}}{{if eq (.status.phase) ("Running")}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}'`
    until [[ "$output" == *nginx* ]]
    do
        info_progress "...";
		let COUNTER=COUNTER+5
		if [[ "$COUNTER" -gt 300 ]]; then
		  echo "FATAL: Failed to install nginx. Please check logs and configuration"
          exit 1
		fi
        sleep 5;
		output=`kubectl get pods -n $NGINX_NAMESPACE -o go-template --template '{{range .items}}{{if eq (.status.phase) ("Running")}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}'`
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
source "$kube_dir/common/kubernetes.sh"

kube_init;


NGINX_CONF_FILE=nginx.yaml;
NGINX_CUSTOM_ADD_HEADER_FILE=custom-add-headers.yaml;
NGINX_CUSTOM_SET_HEADER_FILE=custom-set-headers.yaml;
NGINX_CUSTOM_CONF_FILE=nginx-ingress-nginx-controller.yaml;
NGINX_CUSTOM_CONFIG_FILE=custom_config.yaml;
NGINX_VERSION="${NGINX_VERSION:-v1.4.0}";
NGINX_MOBIUSVIEW_INGRESS_FILE=mobiusview_ingress.yaml;
NGINX_APPMANAGER_INGRESS_FILE=appmanager_ingress.yaml;
NGINX_PROCESSENGINE_INGRESS_FILE=processengine_ingress.yaml;
NGINX_STUDIO_INGRESS_FILE=studio_ingress.yaml;
NGINX_APPAMANGER_AUTH_INGRESS_FILE=appmanager_auth_ingress.yaml;
NGINX_METADATA_EXTRACTION_INGRESS_FILE=metadata_extraction_ingress.yaml;
NGINX_SMART_CLASSIFICATION_INGRESS_FILE=smart_classification_ingress.yaml;
NGINX_CONTENTAUTOMATION_INGRESS_FILE=contentautomation_ingress.yaml;
NGINX_MOBIUS_CONTENTAUTOMATION_PROCESS_INGRESS_FILE=mobius_contentautomation_process_ingress.yaml;

install_nginx;
wait_for_nginx_ready;

if [ "$SMART_CHAT_ENABLED" == "true" ] && [ "$SMART_CHAT_ADMIN_ENABLED" == "true" ]; then

        SMART_CHAT_ADMIN_NGINX_INGRESS_FILE=smart_chat_admin_ingress.yaml;
        #deploy smart-chat-admin-igress
        install_smart_chat_admin_nginx_ingress
fi
