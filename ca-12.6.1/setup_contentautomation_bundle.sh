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

#execute dos2unix
find . -name "*.yaml" -exec dos2unix {} \;
find . -name "*.sh" -exec dos2unix {} \;
dos2unix .env

#Open API KEY value check
if [ $OPENAI_API_KEY == "<REPLACE_WITH_ACTUAL_OPENAI_API_KEY>" ] && [ "$SMART_CHAT_ENABLED" == "true" ]; then
    echo ""
    echo "WARNING: The optional Smart Chat feature requires an OpenAI API key which is not provided as part of the Smart Chat deployment configuration. If you would like to use the Smart Chat feature, please review your Smart Chat deployment configuration entries and add the OpenAI API key and retry the deployment."
fi

#Increase Kube Agent   
if [ $SMART_CHAT_ENABLED == true ]; then
    KUBE_NUM_AGENTS=4
fi

source "$kube_dir/common/kubernetes.sh"

#set up cluster with local registry and push images
$kube_dir/create_k3d_cluster.sh
#create namespace
create_kubernetes_namespace $NAMESPACE;
export DATABASE_NAMESPACE=$NAMESPACE;
export external_database=$EXTERNAL_DATABASE;

#install db
$kube_dir/install_database.sh

#deploy mobius
$kube_dir/deploy_mobius.sh

if [ "$SMART_CHAT_ENABLED" == "true" ]; then
   #deploy opensearch
   $kube_dir/install_opensearch.sh

   #deploy smart-chat
   $kube_dir/deploy_smart_chat.sh

   #deploy smart-chat_indexing_proxy
   $kube_dir/deploy_smart_chat_indexing_proxy.sh

      if [ "$SMART_CHAT_ADMIN_ENABLED" == "true" ]; then
           #deploy smart-chat-admin
           $kube_dir/deploy_smart_chat_admin.sh
      fi
fi
#deploy mobiusview
$kube_dir/deploy_mobiusview.sh

#deploy_contentautomation
$kube_dir/deploy_contentautomation.sh

#deploy_metadata
$kube_dir/deploy_metadata_extraction.sh

#deploy_classification
#$kube_dir/deploy_classification.sh

#deploy nginx
$kube_dir/install_nginx.sh

#Open API KEY value check
if [ $OPENAI_API_KEY == "<REPLACE_WITH_ACTUAL_OPENAI_API_KEY>" ] && [ "$SMART_CHAT_ENABLED" == "true" ]; then
    echo ""
    echo "WARNING: The optional Smart Chat feature requires an OpenAI API key which is not provided as part of the Smart Chat deployment configuration. If you would like to use the Smart Chat feature, please review your Smart Chat deployment configuration entries and add the OpenAI API key and retry the deployment."
fi

if [ $OPENAI_API_KEY == "<REPLACE_WITH_ACTUAL_OPENAI_API_KEY>" ] && [ "$AGENT_TASK_ENABLED" == "true" ]; then
    echo ""
    echo "WARNING: The optional Agent Task feature requires an OpenAI API key which is not provided as part of the processengine.yaml configuration. If you would like to use the Agent Task feature, please review your processengine.yaml configuration entries and add the OpenAI API key and retry the deployment."
fi

