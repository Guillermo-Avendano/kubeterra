#!/bin/bash

source "$kube_dir/common/common.sh"
#source "$kube_dir/pgadmin/pgadmin.sh"

configure_postgresql() {
    POSTGRESQL_VERSION="${POSTGRESQL_VERSION:-16.3.0}";
    info_message "Configuring Postgresql $POSTGRESQL_VERSION resources";
	
    POSTGRES_CONF_FILE=postgres.yaml;
    cp templates/$POSTGRES_CONF_FILE $POSTGRES_CONF_FILE;
    replace_tag_in_file $POSTGRES_CONF_FILE  "<NAME_LOCALREGISTRY>" $NAME_LOCALREGISTRY;
	  replace_tag_in_file $POSTGRES_CONF_FILE  "<PORT_LOCALREGISTRY>" $PORT_LOCALREGISTRY;
    replace_tag_in_file $POSTGRES_CONF_FILE "<image_tag>" $POSTGRESQL_VERSION;
    replace_tag_in_file $POSTGRES_CONF_FILE "<database_user>" $POSTGRESQL_USERNAME;
    replace_tag_in_file $POSTGRES_CONF_FILE "<database_password>" $POSTGRESQL_PASSWORD;
    replace_tag_in_file $POSTGRES_CONF_FILE "<database_name_mobiusview>" $POSTGRESQL_DBNAME_MOBIUSVIEW;
    replace_tag_in_file $POSTGRES_CONF_FILE "<database_name_mobius>" $POSTGRESQL_DBNAME_MOBIUS;
	  replace_tag_in_file $POSTGRES_CONF_FILE "<database_name_appmanager>" $POSTGRESQL_DBNAME_APPMANAGER;
    replace_tag_in_file $POSTGRES_CONF_FILE "<database_name_studio>" $POSTGRESQL_DBNAME_STUDIO;
    replace_tag_in_file $POSTGRES_CONF_FILE "<database_name_processengine_flowable>" $POSTGRESQL_DBNAME_PROCESSENGINE_FLOWABLE;
    replace_tag_in_file $POSTGRES_CONF_FILE "<database_name_processengine_root>" $POSTGRESQL_DBNAME_PROCESSENGINE_ROOT;
	  replace_tag_in_file $POSTGRES_CONF_FILE "<postgres_port>" $POSTGRESQL_PORT;
	  replace_tag_in_file $POSTGRES_CONF_FILE "<IMAGE_NAME_POSTGRES>" $IMAGE_NAME_POSTGRES;
	  replace_tag_in_file $POSTGRES_CONF_FILE "<PUBLIC_DOCKER_REGISTRY>" $PUBLIC_DOCKER_REGISTRY;
	  #replace_tag_in_file $POSTGRES_CONF_FILE "<database_name_smart_classification>" $POSTGRESQL_DBNAME_SMART_CLASSIFICATION;

}

install_postgresql() {
    info_message "Creating database namespace and storage";
    create_kubernetes_namespace $DATABASE_NAMESPACE;
	
	POSTGRES_VOLUME=`eval echo ~/${NAMESPACE}_data/postgres`
	
	POSTGRES_STORAGE_FILE=postgres-storage.yaml;
    cp $kube_dir/database/storage/local/templates/$POSTGRES_STORAGE_FILE $kube_dir/database/storage/local/$POSTGRES_STORAGE_FILE;
	replace_tag_in_file $kube_dir/database/storage/local/$POSTGRES_STORAGE_FILE "<POSTGRES_VOLUME>" $POSTGRES_VOLUME;

    if [ "$KUBERNETES_TYPE" == "eks" ]; then
        $KUBE_CLI_EXE apply -f storage/aws/postgres.yaml --namespace $DATABASE_NAMESPACE;
    elif [ "$KUBERNETES_TYPE" == "rosa" ] || [ "$KUBERNETES_TYPE" == "okd" ]; then
        $KUBE_CLI_EXE apply -f storage/openshift/postgres.yaml --namespace $DATABASE_NAMESPACE;
    else
        $KUBE_CLI_EXE apply -f storage/local/postgres-storage.yaml --namespace $DATABASE_NAMESPACE;
    fi

    configure_postgresql;

    info_message "Deploying postgresql Helm chart";

	helm install postgresql $kube_dir/helm_charts/postgresql.tgz --namespace $DATABASE_NAMESPACE  -f $kube_dir/database/$POSTGRES_CONF_FILE \
  --set global.security.allowInsecureImages=true

	rm -f $kube_dir/database/storage/local/$POSTGRES_STORAGE_FILE
	rm -f $kube_dir/database/postgres.yaml
}

uninstall_postgresql() {
    helm uninstall postgresql --namespace $DATABASE_NAMESPACE;

    if [ "$KUBERNETES_TYPE" == "eks" ]; then
        $KUBE_CLI_EXE delete -f storage/aws/postgres.yaml --namespace $DATABASE_NAMESPACE;
    elif [ "$KUBERNETES_TYPE" == "rosa" ] || [ "$KUBERNETES_TYPE" == "okd" ]; then
        $KUBE_CLI_EXE delete -f storage/openshift/postgres.yaml --namespace $DATABASE_NAMESPACE;
    else
        $KUBE_CLI_EXE delete -f storage/local/postgres.yaml --namespace $DATABASE_NAMESPACE;
    fi

    if [ "$KUBERNETES_TYPE" == "crc" ]; then
        $KUBE_CLI_EXE delete project $DATABASE_NAMESPACE;
    else
        $KUBE_CLI_EXE delete namespace $DATABASE_NAMESPACE;
    fi
}

get_postgres_status() {
    $KUBE_CLI_EXE get pods --namespace $DATABASE_NAMESPACE postgresql-0 -o jsonpath="{.status.phase}" 2>/dev/null
}

configure_port_forwarding() {
    $KUBE_CLI_EXE port-forward --namespace $DATABASE_NAMESPACE postgresql-0 5432:5432 &
}

wait_for_postgres_ready() {
    until [ "$(get_postgres_status)" == "Running" ]
    do
        info_progress "...";
        sleep 5;
    done
}

#configure_postgres() {
#    pushd $kube_dir/pgadmin
#    install_pgadmin;
#    popd
#}

get_postgres_service() {
    echo "postgresql.shared"
}

get_postgres_port() {
    echo "5432"
}
