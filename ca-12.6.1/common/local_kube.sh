#!/bin/bash

kube_init() {
  if [ "$KUBERNETES_TYPE" == "k3d" ]; then  
    KUBE_EXE="k3d"
    KUBE_CLI_EXE="kubectl"
    CONTAINER_EXE="docker"
  elif [ "$KUBERNETES_TYPE" == "rosa" ]; then
    KUBE_EXE=""
    KUBE_CLI_EXE="oc"
    CONTAINER_EXE="podman"    
  elif [ "$KUBERNETES_TYPE" == "okd" ]; then
    KUBE_EXE=""
    KUBE_CLI_EXE="oc"
    CONTAINER_EXE="podman"
  elif [ "$KUBERNETES_TYPE" == "crc" ]; then
    KUBE_EXE="crc"
    KUBE_CLI_EXE="oc"
    CONTAINER_EXE="podman"
  elif [ "$KUBERNETES_TYPE" == "eks" ]; then
    KUBE_EXE=""
    KUBE_CLI_EXE="kubectl"
    CONTAINER_EXE="docker"
  elif [ "$KUBERNETES_TYPE" == "minikube" ]; then
    KUBE_EXE="minikube"
    if ! command_exists $KUBE_EXE; then
      KUBE_EXE="k3d"
      KUBE_CLI_EXE="kubectl"
      CONTAINER_EXE="docker"
    fi
  fi
}

check_cluster_exists() {
    #TODO: Needed to add minikube
    $KUBE_EXE cluster list 2>/dev/null | grep -q "$KUBE_CLUSTER_NAME"
}

get_kubeconfig() {
  if [ "$KUBERNETES_TYPE" == "k3d" ]; then
    $KUBE_EXE kubeconfig get $KUBE_CLUSTER_NAME 2>/dev/null
  elif [ "$KUBERNETES_TYPE" == "minikube" ]; then
    cat ~/.minikube/profiles/config.json 2>/dev/null
  elif [ "$KUBERNETES_TYPE" == "crc" ]; then
    $KUBE_CLI_EXE config view --raw 2>/dev/null;
  fi
}

save_kubeconfig() {
  if [ "$KUBERNETES_TYPE" == "k3d" ]; then
    $KUBE_EXE kubeconfig get $KUBE_CLUSTER_NAME >"$(pwd)/CA-kubeconfig"
  elif [ "$KUBERNETES_TYPE" == "minikube" ]; then
    cp ~/.minikube/profiles/$KUBE_CLUSTER_NAME/config.json "$(pwd)/CA-kubeconfig"
  elif [ "$KUBERNETES_TYPE" == "crc" ]; then
    $KUBE_CLI_EXE config view --raw >"$(pwd)/CA-kubeconfig";
  fi
}

check_cluster_connection() {
  export KUBECONFIG=$CA_KUBECONFIG
  info_message "Showing some cluster info:"
  $KUBE_CLI_EXE cluster-info 
}

cluster_connection() {
  kc=$(get_kubeconfig)
  [ -n "$kc" ] || echo "could not obtain a valid KUBECONFIG from $KUBERNETES_TYPE"
  save_kubeconfig;

  CA_KUBECONFIG="$(pwd)/CA-kubeconfig"
  check_cluster_connection;
}

export_cluster_config() {
  cluster_connection;
}

create_cluster() {
  info_message "Creating kubernetes cluster $KUBE_CLUSTER_NAME"

  if [ "$REGISTRY_TYPE" == "local" ]; then
    if [ "$KUBERNETES_TYPE" == "k3d" ]; then
      echo $KUBE_EXE cluster create ${KUBE_CLUSTER_NAME} --agents $KUBE_NUM_AGENTS -p $NGINX_EXTERNAL_TLS_PORT:443@loadbalancer -p 80:80@loadbalancer -p 30710:30710@loadbalancer -p 30711:30711@loadbalancer -p 30712:30712@loadbalancer -p 30713:30713@loadbalancer -p 30714:30714@loadbalancer -p 30715:30715@loadbalancer $KUBE_ARGS $KUBE_REGISTRY --k3s-arg "--disable=traefik@server:0"
      $KUBE_EXE cluster create ${KUBE_CLUSTER_NAME} --agents $KUBE_NUM_AGENTS -p $NGINX_EXTERNAL_TLS_PORT:443@loadbalancer -p 80:80@loadbalancer -p 30710:30710@loadbalancer -p 30711:30711@loadbalancer -p 30712:30712@loadbalancer -p 30713:30713@loadbalancer -p 30714:30714@loadbalancer -p 30715:30715@loadbalancer $KUBE_ARGS $KUBE_REGISTRY --k3s-arg "--disable=traefik@server:0"
    elif [ "$KUBERNETES_TYPE" == "minikube" ]; then
      echo $KUBE_EXE start -p ${KUBE_CLUSTER_NAME} $KUBE_NUM_AGENTS $KUBE_ARGS $KUBE_REGISTRY --k3s-arg "--disable=traefik@server:0"
      #TODO: Needed to add full minikube settings (ports...)
      $KUBE_EXE start -p ${KUBE_CLUSTER_NAME}
    fi
  else
    if [ "$KUBERNETES_TYPE" == "k3d" ]; then
      echo $KUBE_EXE cluster create ${KUBE_CLUSTER_NAME} --agents $KUBE_NUM_AGENTS -p $NGINX_EXTERNAL_TLS_PORT:443@loadbalancer -p 80:80@loadbalancer -p 30710:30710@loadbalancer -p 30711:30711@loadbalancer -p 30712:30712@loadbalancer -p 30713:30713@loadbalancer -p 30714:30714@loadbalancer -p 30715:30715@loadbalancer $KUBE_ARGS --k3s-arg "--disable=traefik@server:0"
      $KUBE_EXE cluster create ${KUBE_CLUSTER_NAME} --agents $KUBE_NUM_AGENTS -p $NGINX_EXTERNAL_TLS_PORT:443@loadbalancer -p 80:80@loadbalancer -p 30710:30710@loadbalancer -p 30711:30711@loadbalancer -p 30712:30712@loadbalancer -p 30713:30713@loadbalancer -p 30714:30714@loadbalancer -p 30715:30715@loadbalancer $KUBE_ARGS --k3s-arg "--disable=traefik@server:0"
    elif [ "$KUBERNETES_TYPE" == "minikube" ]; then
      echo $KUBE_EXE start -p ${KUBE_CLUSTER_NAME} $KUBE_NUM_AGENTS $KUBE_ARGS --k3s-arg "--disable=traefik@server:0"
      #TODO: Needed to add full minikube settings (ports...)
      $KUBE_EXE start -p ${KUBE_CLUSTER_NAME}
    fi
  fi

  sleep 3
  cluster_connection;
}

kube_delete_cluster() {
  if [ "$KUBERNETES_TYPE" == "k3d" ]; then
    $KUBE_EXE cluster delete $1
  elif [ "$KUBERNETES_TYPE" == "crc" ]; then
    $KUBE_EXE stop
    $KUBE_EXE delete
  else
    $KUBE_EXE stop -p $1
    $KUBE_EXE delete -p $1
  fi
}

create_local_cluster() {
  kube_init
  info_message "Checking if kubernetes provider is installed"

  if ! command_exists $KUBE_EXE; then
    info_message "Kubernetes provider isn't installed. Please, install it and re-run"
    exit 1

    #automate the crc installation

  else
    info_message "Kubernetes provider seems to be installed"
  fi

  info_message "Local registry management"

  create_registry;
  push_images_to_local_registry;

  info_message "Creating $KUBE_CLUSTER_NAME cluster"

  if check_cluster_exists; then
    info_message "Cluster $KUBE_CLUSTER_NAME already exists"
    cluster_connection;
  else
    create_cluster;
  fi
}

remove_services(){
  info_message "Removing existing services"
	if [[ $(helm ls -q -n $NAMESPACE) ]]; then 
	  for OUTPUT in $( helm ls -q -n mobius); do 
	    helm uninstall -n $NAMESPACE $OUTPUT;
        info_message "Waiting termination  $OUTPUT"
		sleep 30;		
	  done  
	fi
}

create_local_cluster_remove_existing() {
  kube_init
  info_message "Checking if kubernetes provider is installed"

  if ! command_exists $KUBE_EXE; then
    info_message "Kubernetes provider isn't installed. Please, install it and re-run"
    exit 1
  else
    info_message "Kubernetes provider seems to be installed"
  fi

  info_message "Local registry management"

  create_registry;
  push_images_to_local_registry;

  info_message "Creating $KUBE_CLUSTER_NAME cluster"
  if check_cluster_exists; then
    info_message "Cluster $KUBE_CLUSTER_NAME already exists"
	remove_services;
	info_message "Removing existing cluster"
	kube_delete_cluster "${KUBE_CLUSTER_NAME:-mobius}";
	info_message "Waiting termination"
	sleep 30;  
  fi  
  create_cluster;
  
}

start_cluster(){
  kube_init
  if check_cluster_exists; then
    info_message "Starting cluster $KUBE_CLUSTER_NAME"
	$KUBE_EXE cluster start $KUBE_CLUSTER_NAME 
  else
    info_message "Cluster $KUBE_CLUSTER_NAME does not exists. Please create cluster $KUBE_CLUSTER_NAME"
    exit 1	
  fi
}

stop_cluster(){
  kube_init
  if check_cluster_exists; then
    info_message "Stopping cluster $KUBE_CLUSTER_NAME"
	$KUBE_EXE cluster stop $KUBE_CLUSTER_NAME 
  else
    info_message "Cluster $KUBE_CLUSTER_NAME does not exists."
    exit 1	
  fi
}