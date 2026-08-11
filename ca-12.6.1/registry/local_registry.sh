#!/bin/bash

source "$kube_dir/common/common.sh"

tag_images(){
    # Check if SMART_CHAT_SOURCE_DOCKER_REGISTRY is commented
    local smart_chat_registry_src=${SMART_CHAT_SOURCE_DOCKER_REGISTRY:-$SOURCE_DOCKER_REGISTRY}

    # Check if METADATA_EXTRACTION_SOURCE_DOCKER_REGISTRY is commented
    local meta_registry_src=${METADATA_EXTRACTION_SOURCE_DOCKER_REGISTRY:-$SOURCE_DOCKER_REGISTRY}

    local registry_src=${SOURCE_DOCKER_REGISTRY}
    local public_registry_src=${PUBLIC_DOCKER_REGISTRY}
   # local smart_registry_src=${SMART_CLASSIFICATION_DOCKER_REGISTRY}
    local registry_target=${DNS_LOCALREGISTRY}:${PORT_LOCALREGISTRY}

	declare -A images
    images[${IMAGE_NAME_MOBIUS}]=${IMAGE_VERSION_MOBIUS}
    images[${IMAGE_NAME_MOBIUSVIEW}]=${IMAGE_VERSION_MOBIUSVIEW}
		images[${IMAGE_NAME_APPMANAGER}]=${IMAGE_VERSION_APPMANAGER}
  	images[${IMAGE_NAME_STUDIO}]=${IMAGE_VERSION_STUDIO}
  	images[${IMAGE_NAME_PROCESSENGINE}]=${IMAGE_VERSION_PROCESSENGINE}
  	images[${IMAGE_NAME_METADATA_EXTRACTION}]=${IMAGE_VERSION_METADATA_EXTRACTION}
  	#images[${IMAGE_NAME_SMART_CLASSIFICATION}]=${IMAGE_VERSION_SMART_CLASSIFICATION}
  	images[${IMAGE_NAME_POSTGRES}]=${POSTGRESQL_VERSION}
  	images[${IMAGE_NAME_OPENSEARCH}]=${OPENSEARCH_VERSION}
  	images[${IMAGE_INITHELPER_OPENSEARCH_BUSYBOX}]="latest"

    for key in ${!images[@]}; do
        if [ "$key" == "${IMAGE_NAME_METADATA_EXTRACTION}" ]; then
            $CONTAINER_EXE tag ${meta_registry_src}/${key}:${images[${key}]} ${registry_target}/${key}:${images[${key}]}
#		elif [ "$key" == "${IMAGE_NAME_SMART_CLASSIFICATION}" ]; then
#            $CONTAINER_EXE tag ${smart_registry_src}/${key}:${images[${key}]} ${registry_target}/${key}:${images[${key}]}
        elif [ "$key" == "${IMAGE_NAME_POSTGRES}" ] || [ "$key" == "${IMAGE_NAME_OPENSEARCH}" ] || [ "$key" == "${IMAGE_INITHELPER_OPENSEARCH_BUSYBOX}" ]; then
            $CONTAINER_EXE tag ${public_registry_src}/${key}:${images[${key}]} ${registry_target}/${key}:${images[${key}]}
        else
            $CONTAINER_EXE tag ${registry_src}/${key}:${images[${key}]} ${registry_target}/${key}:${images[${key}]}
        fi
    done

    if [ "$SMART_CHAT_ENABLED" == "true" ]; then
            $CONTAINER_EXE tag ${smart_chat_registry_src}/${IMAGE_NAME_SMART_CHAT}:${IMAGE_VERSION_SMART_CHAT} ${registry_target}/${IMAGE_NAME_SMART_CHAT}:${IMAGE_VERSION_SMART_CHAT}
            $CONTAINER_EXE tag ${smart_chat_registry_src}/${IMAGE_NAME_SMART_CHAT_QUERY_LOGS}:${IMAGE_VERSION_SMART_CHAT_QUERY_LOGS} ${registry_target}/${IMAGE_NAME_SMART_CHAT_QUERY_LOGS}:${IMAGE_VERSION_SMART_CHAT_QUERY_LOGS}
            $CONTAINER_EXE tag ${smart_chat_registry_src}/${IMAGE_NAME_SMART_CHAT_INDEXING_PROXY}:${IMAGE_VERSION_SMART_CHAT_INDEXING_PROXY} ${registry_target}/${IMAGE_NAME_SMART_CHAT_INDEXING_PROXY}:${IMAGE_VERSION_SMART_CHAT_INDEXING_PROXY}

            if [ "$SMART_CHAT_ADMIN_ENABLED" == "true" ]; then
                        local registry_src_admin=${SMART_CHAT_SOURCE_DOCKER_REGISTRY}
                        $CONTAINER_EXE tag ${registry_src_admin}/${IMAGE_NAME_SMART_CHAT_ADMIN}:${IMAGE_VERSION_SMART_CHAT_ADMIN} ${registry_target}/${IMAGE_NAME_SMART_CHAT_ADMIN}:${IMAGE_VERSION_SMART_CHAT_ADMIN}
            fi
    fi
}


push_images_to_local_registry(){
    if [ "$REGISTRY_TYPE" == "local" ]; then
        if [ "$PUSH_IMAGES_LOCALREGISTRY" == "true" ]; then
		    info_message "Tag images"
			tag_images;
            info_message "Push images"
            push_images;
        else
            info_message "Skip pushing images to the local registry $NAME_LOCALREGISTRY"
        fi
    fi
}

push_images(){
    local registry_target=${DNS_LOCALREGISTRY}:${PORT_LOCALREGISTRY}

    declare -A images
    images[${IMAGE_NAME_MOBIUS}]=${IMAGE_VERSION_MOBIUS}
    images[${IMAGE_NAME_MOBIUSVIEW}]=${IMAGE_VERSION_MOBIUSVIEW}
		images[${IMAGE_NAME_APPMANAGER}]=${IMAGE_VERSION_APPMANAGER}
  	images[${IMAGE_NAME_STUDIO}]=${IMAGE_VERSION_STUDIO}
  	images[${IMAGE_NAME_PROCESSENGINE}]=${IMAGE_VERSION_PROCESSENGINE}
  	images[${IMAGE_NAME_METADATA_EXTRACTION}]=${IMAGE_VERSION_METADATA_EXTRACTION}
  	#images[${IMAGE_NAME_SMART_CLASSIFICATION}]=${IMAGE_VERSION_SMART_CLASSIFICATION}
  	images[${IMAGE_NAME_POSTGRES}]=${POSTGRESQL_VERSION}
  	images[${IMAGE_NAME_OPENSEARCH}]=${OPENSEARCH_VERSION}
  	images[${IMAGE_INITHELPER_OPENSEARCH_BUSYBOX}]="latest"

    for key in ${!images[@]}; do
        $CONTAINER_EXE push ${registry_target}/${key}:${images[${key}]}
    done

    if [ "$SMART_CHAT_ENABLED" == "true" ]; then
            $CONTAINER_EXE push ${registry_target}/${IMAGE_NAME_SMART_CHAT}:${IMAGE_VERSION_SMART_CHAT}
            $CONTAINER_EXE push ${registry_target}/${IMAGE_NAME_SMART_CHAT_QUERY_LOGS}:${IMAGE_VERSION_SMART_CHAT_QUERY_LOGS}
            $CONTAINER_EXE push ${registry_target}/${IMAGE_NAME_SMART_CHAT_INDEXING_PROXY}:${IMAGE_VERSION_SMART_CHAT_INDEXING_PROXY}

    if [ "$SMART_CHAT_ADMIN_ENABLED" == "true" ]; then
            local registry_src=${SMART_CHAT_SOURCE_DOCKER_REGISTRY}
            $CONTAINER_EXE push ${registry_target}/${IMAGE_NAME_SMART_CHAT_ADMIN}:${IMAGE_VERSION_SMART_CHAT_ADMIN}

    fi
    fi
}

create_registry(){
    if [ "$REGISTRY_TYPE" == "local" ]; then
        if [ "$CREATE_LOCALREGISTRY" == "true" ]; then
		    if check_registry_exists; then
              delete_registry;
	        fi  
            info_message "Creating registry $NAME_LOCALREGISTRY"
            #$KUBE_EXE registry create $NAME_LOCALREGISTRY --port 0.0.0.0:${PORT_LOCALREGISTRY}
			$KUBE_EXE registry create $NAME_LOCALREGISTRY --port ${PORT_LOCALREGISTRY}
        else 
            info_message "Using existing registry $NAME_LOCALREGISTRY"
        fi
    else
        info_message "Skipping this step as registry REGISTRY_TYPE environemnt variable is not 'local'"
    fi
}

delete_registry(){
    if [ "$REGISTRY_TYPE" == "local" ]; then
        info_message "deleting registry $NAME_LOCALREGISTRY"
        $KUBE_EXE registry delete $NAME_LOCALREGISTRY    
    fi
}

check_registry_exists() {
    #TODO: Needed to add minikube
    $KUBE_EXE registry list 2>/dev/null | grep -q "$NAME_LOCALREGISTRY"
}