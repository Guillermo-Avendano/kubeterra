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
source "$kube_dir/database/database.sh"
source "$kube_dir/common/kubernetes.sh"

#TODO read arguments and print help
kube_init;
export DATABASE_NAMESPACE=$NAMESPACE;
export external_database=$EXTERNAL_DATABASE;

highlight_message "Deploying database services"

    if [ "$external_database" == "false" ]; then
        pushd $kube_dir/database
        install_database;

        info_progress_header "Waiting for database services to be ready ...";
        wait_for_database_ready;
        info_message "The database services are ready now.";

        #postinstall_database;
        popd
    else
        info_message "Skip database services deployment because the environment will use an external database server."
    fi