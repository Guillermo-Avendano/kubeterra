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
source "$kube_dir/registry/local_registry.sh"

#TODO read arguments and print help
kube_init;

highlight_message "Create/Access Kubernetes Cluster"
info_message "Creating a new local cluster"

#set up volumes
MOBIUS_PV_VOLUME=`eval echo ~/${NAMESPACE}_data/mobius/pv`
if [ ! -d $MOBIUS_PV_VOLUME ]; then
  mkdir -p $MOBIUS_PV_VOLUME;
  chmod -R 777 $MOBIUS_PV_VOLUME;  
fi
MOBIUS_FTS_VOLUME=`eval echo ~/${NAMESPACE}_data/mobius/fts`
if [ ! -d $MOBIUS_FTS_VOLUME ]; then
  mkdir -p $MOBIUS_FTS_VOLUME;
  chmod -R 777 $MOBIUS_FTS_VOLUME;
fi
MOBIUS_DIAGNOSTIC_VOLUME=`eval echo ~/${NAMESPACE}_data/mobius/log`
if [ ! -d $MOBIUS_DIAGNOSTIC_VOLUME ]; then
  mkdir -p $MOBIUS_DIAGNOSTIC_VOLUME;
  chmod -R 777 $MOBIUS_DIAGNOSTIC_VOLUME;
fi
MOBIUSVIEW_PV_VOLUME=`eval echo ~/${NAMESPACE}_data/mobiusview/pv`
if [ ! -d $MOBIUSVIEW_PV_VOLUME ]; then
  mkdir -p $MOBIUSVIEW_PV_VOLUME;
  chmod -R 777 $MOBIUSVIEW_PV_VOLUME;  
fi
MOBIUSVIEW_DIAGNOSTIC_VOLUME=`eval echo ~/${NAMESPACE}_data/mobiusview/log`
if [ ! -d $MOBIUSVIEW_DIAGNOSTIC_VOLUME ]; then
  mkdir -p $MOBIUSVIEW_DIAGNOSTIC_VOLUME;
  chmod -R 777 $MOBIUSVIEW_DIAGNOSTIC_VOLUME;
fi
COMMON_VOLUME=`eval echo ~/${NAMESPACE}_data/common`
if [ ! -d $COMMON_VOLUME ]; then
  mkdir -p $COMMON_VOLUME;
  chmod -R 777 $COMMON_VOLUME;
fi
POSTGRES_VOLUME=`eval echo ~/${NAMESPACE}_data/postgres`
if [ ! -d $POSTGRES_VOLUME ]; then
  mkdir -p $POSTGRES_VOLUME;
  chmod -R 777 $POSTGRES_VOLUME;
fi
APPMANAGER_PV_VOLUME=`eval echo ~/${NAMESPACE}_data/appmanager/pv`
if [ ! -d $APPMANAGER_PV_VOLUME ]; then
  mkdir -p $APPMANAGER_PV_VOLUME;
  chmod -R 777 $APPMANAGER_PV_VOLUME;
fi
STUDIO_PV_VOLUME=`eval echo ~/${NAMESPACE}_data/studio/pv`
if [ ! -d $STUDIO_PV_VOLUME ]; then
  mkdir -p $STUDIO_PV_VOLUME;
  chmod -R 777 $STUDIO_PV_VOLUME;
fi
OPENSEARCH_VOLUME=`eval echo ~/${NAMESPACE}_data/opensearch`
if [ ! -d "$OPENSEARCH_VOLUME" ] && [ "$SMART_CHAT_ENABLED" == "true" ]; then
  mkdir -p $OPENSEARCH_VOLUME;
  chmod -R 777 $OPENSEARCH_VOLUME;
fi
#set env
# extra args can be used to add other volume mounts or other arguments
VOLUME_MAPPING="--volume $MOBIUS_PV_VOLUME:$MOBIUS_PV_VOLUME --volume $MOBIUS_DIAGNOSTIC_VOLUME:$MOBIUS_DIAGNOSTIC_VOLUME --volume $MOBIUS_FTS_VOLUME:$MOBIUS_FTS_VOLUME --volume $MOBIUSVIEW_PV_VOLUME:$MOBIUSVIEW_PV_VOLUME --volume $MOBIUSVIEW_DIAGNOSTIC_VOLUME:$MOBIUSVIEW_DIAGNOSTIC_VOLUME --volume  $OPENSEARCH_VOLUME:$OPENSEARCH_VOLUME --volume $POSTGRES_VOLUME:$POSTGRES_VOLUME --volume  $APPMANAGER_PV_VOLUME:$APPMANAGER_PV_VOLUME --volume  $STUDIO_PV_VOLUME:$STUDIO_PV_VOLUME --volume $COMMON_VOLUME:/var/lib/rancher/k3s/storage@all"
if [ -z $KUBE_CLUSTER_EXTRA_ARGS]; then
  KUBE_ARGS="$VOLUME_MAPPING --wait";
else
  KUBE_ARGS="$VOLUME_MAPPING $KUBE_CLUSTER_EXTRA_ARGS --wait";
fi  

KUBE_REGISTRY="--registry-use http://k3d-${NAME_LOCALREGISTRY:-mobius}:${PORT_LOCALREGISTRY:-5000}"

#Create a local cluster and push images.
create_local_cluster_remove_existing;

