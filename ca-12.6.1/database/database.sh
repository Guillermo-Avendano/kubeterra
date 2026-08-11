#!/bin/bash

source "$kube_dir/common/common.sh"
source "$kube_dir/database/postgres.sh"


install_database() {
    info_message "Installing $DATABASE_PROVIDER database ..."

    if [ "$DATABASE_PROVIDER" == "postgresql" ]; then
        install_postgresql;
    else
        error_message "Unexpected DATABASE_PROVIDER value: $DATABASE_PROVIDER";
    fi
}

uninstall_database() {
    info_message "Uninstalling $DATABASE_PROVIDER database ..."

    if [ "$DATABASE_PROVIDER" == "postgresql" ]; then
        uninstall_postgresql;
    else
        error_message "Unexpected DATABASE_PROVIDER value: $DATABASE_PROVIDER";
    fi
}

wait_for_database_ready() {
    if [ "$DATABASE_PROVIDER" == "postgresql" ]; then
        wait_for_postgres_ready;
    else
        error_message "Unexpected DATABASE_PROVIDER value: $DATABASE_PROVIDER";
    fi
}

get_conf_filename() {
    local conf_filename

    if [ "$DATABASE_PROVIDER" == "postgresql" ]; then
        if [ "$MOBIUS_CUSTOM_THEME" != "" ]; then
            conf_filename="base-configuration-postgres-custom-theme.yaml"
        else
            conf_filename="base-configuration-postgres.yaml"
        fi
    fi

    echo $conf_filename
}

postinstall_database() {
    info_message ""
    #if [ "$DATABASE_PROVIDER" == "postgresql" ]; then
    #    configure_postgres;
    #else
    #    error_message "Unexpected DATABASE_PROVIDER value: $DATABASE_PROVIDER";
    #fi
}

database_ssl_certificates() {
    local solution_namespace=$1;

    
}

get_database_service() {
    local service_name;

    if [ "$DATABASE_PROVIDER" == "postgresql" ]; then
        service_name="$(get_postgres_service)";
    else
        error_message "Unexpected DATABASE_PROVIDER value: $DATABASE_PROVIDER";
    fi

    echo "$service_name"
}

get_database_port() {
    local port;

    if [ "$DATABASE_PROVIDER" == "postgresql" ]; then
        port="$(get_postgres_port)";
    else
        error_message "Unexpected DATABASE_PROVIDER value: $DATABASE_PROVIDER";
    fi

    echo "$port"
}
