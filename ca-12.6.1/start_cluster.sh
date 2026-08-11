#!/bin/bash
#abort in case of cmd failure
set -Eeuo pipefail

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
start_cluster;

#Reload NGINX to make sure mobius view endpoint is up when NGINX pod starts.
info_message "Reload NGINX. This will take few minutes"
kubectl scale deployment nginx-ingress-nginx-controller --replicas=0 -n ingress-nginx
sleep 120;
kubectl scale deployment nginx-ingress-nginx-controller --replicas=1 -n ingress-nginx
sleep 30;

#Uncomment if k3d portforwarding does not work
#info_message "NGINX Portforward"
#$KUBE_CLI_EXE port-forward --address 0.0.0.0 --namespace=$NGINX_NAMESPACE service/nginx-ingress-nginx-controller $NGINX_EXTERNAL_TLS_PORT:443 >/dev/null 2>&1 &	

