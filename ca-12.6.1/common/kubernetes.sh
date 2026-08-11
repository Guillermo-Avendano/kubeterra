#!/bin/bash

source "$kube_dir/common/common.sh"
source "$kube_dir/common/local_kube.sh"

check_if_kubernetes_resource_exists() {
    kube_init;
    local restype=$1;
    local resname=$2;
    local namespace=$3;
    local exists=$($KUBE_CLI_EXE get $restype $resname --namespace $namespace --ignore-not-found);
    local result=true;
    if [ -z "$exists" ]; then
        result=false;
    fi
    echo $result 2>/dev/null;
}

check_if_kubernetes_namespace_exists() {
    kube_init;
    local resname=$1;
    local command='';
    local exists=false;
    local result=true;

    if [ "$KUBERNETES_TYPE" == "rosa" ] || [ "$KUBERNETES_TYPE" == "okd" ] || [ "$KUBERNETES_TYPE" == "crc" ]; then
        exists=$($KUBE_CLI_EXE get project $resname --ignore-not-found);
    else
        exists=$($KUBE_CLI_EXE get namespace $resname --ignore-not-found);
    fi

    if [ -z "$exists" ]; then
        result=false;
    fi
    echo $result 2>/dev/null;
}

create_kubernetes_namespace() {
    kube_init;
    local namespace=$1
    exists=$(check_if_kubernetes_namespace_exists $namespace);

    if [ "$exists" == "true" ]; then
        info_message "Skip creating $namespace namespace because it already exists"
    else
        info_message "Creating $namespace namespace"
        
        if [ "$KUBERNETES_TYPE" == "rosa" ] || [ "$KUBERNETES_TYPE" == "okd" ] || [ "$KUBERNETES_TYPE" == "crc" ]; then
            $KUBE_CLI_EXE new-project $namespace	    
            $KUBE_CLI_EXE adm policy add-scc-to-user privileged -z default -n $namespace
            $KUBE_CLI_EXE adm policy add-scc-to-group privileged system:authenticated
            $KUBE_CLI_EXE adm policy add-scc-to-group hostmount-anyuid system:authenticated
        else
            $KUBE_CLI_EXE create namespace $namespace
        fi
    fi
}
