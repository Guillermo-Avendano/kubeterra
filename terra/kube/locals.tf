# ======================================================
# Terraform Local Values
# ======================================================
# Local values are computed values that are used across
# the configuration. They help reduce duplication and
# improve maintainability.

locals {
  # Common namespace
  namespace = var.var_namespace_mobius

  # Common labels applied to all resources
  common_labels = merge(
    var.common_labels,
    {
      namespace   = local.namespace
      managed_by  = "terraform"
      project     = "mobius"
      created_at  = timestamp()
    }
  )

  # ======================================================
  # DOCKER REGISTRY CONFIGURATION
  # ======================================================
  docker_registry = {
    mobius_server        = var.var_mobiusserver_docker_artifactory_url
    mobius_view          = var.var_mobiusview_docker_artifactory_url
    event_analytics      = var.var_eventanalytics_docker_artifactory_url
    appmanager           = var.var_appmanager_docker_artifactory_url
    studio               = var.var_studio_docker_artifactory_url
    processengine        = var.var_processengine_docker_artifactory_url
    smart_chat           = var.var_smart_chat_docker_artifactory_url
    smart_chat_indexing  = var.var_smart_chat_indexing_proxy_docker_artifactory_url
    smart_chat_query_logs = var.var_smart_chat_query_logs_docker_artifactory_url
  }

  # ======================================================
  # IMAGE VERSIONS
  # ======================================================
  image_versions = {
    mobius_server        = var.var_mobiusserver_image
    mobius_view          = var.var_mobiusview_image
    event_analytics      = var.var_eventanalytics_image
    appmanager           = var.var_appmanager_image
    studio               = var.var_studio_image
    processengine        = var.var_processengine_image
    smart_chat           = var.var_smart_chat_image
    smart_chat_indexing  = var.var_smart_chat_indexing_proxy_image
    smart_chat_query_logs = var.var_smart_chat_query_logs_image
  }

  # ======================================================
  # HELM CHARTS
  # ======================================================
  helm_charts = {
    mobius_server             = var.var_mobiusserver_chart_file
    mobius_view               = var.var_mobiusview_chart_file
    event_analytics           = var.var_eventanalytics_chart_file
    appmanager                = var.var_appmanager_chart_file
    studio                    = var.var_studio_chart_file
    processengine             = var.var_processengine_chart_file
    smart_chat                = var.var_smart_chat_chart_file
    smart_chat_indexing_proxy = var.var_smart_chat_indexing_proxy_chart_file
  }

  # ======================================================
  # DATABASE CONFIGURATION
  # ======================================================
  database = {
    provider              = var.var_database_provider
    hostname              = var.var_database_hostname
    port                  = var.var_database_port
    user                  = var.var_database_user
    driver_class_name     = var.var_database_driver_class_name
    platform              = var.var_database_platform
    sslmode               = try(var.var_database_sslmode, "disable")
    create_schema_required = var.var_create_database_schema_required
  }

  # Database schemas
  database_schemas = {
    mobius_server   = var.var_database_mobiusserver_schema
    mobius_view     = var.var_database_mobiusview_schema
    event_analytics = var.var_database_eventanalytics_schema
    appmanager      = var.var_database_appmanager_schema
    studio          = var.var_database_studio_schema
    processengine_flowable = var.var_database_processengine_flowable_schema
    processengine_root     = var.var_database_processengine_root_schema
  }

  # ======================================================
  # STORAGE CONFIGURATION
  # ======================================================
  storage = {
    pvc_enabled       = var.var_pvc_enabled
    storage_class     = var.var_pvc_storage_class
    mobius_pvc        = var.var_mobius_pvc_name
    mobius_fts_pvc    = var.var_mobius_fts_pvc_name
    mobius_diag_pvc   = var.var_mobius_diag_pvc_name
    archive_file_path = var.var_mobius_server_archive_file_path
  }

  # ======================================================
  # IMAGE PULL SECRETS
  # ======================================================
  image_pull_secrets = {
    mobius      = var.var_mobius_image_pull_secret
    smart_chat  = var.var_smart_chat_image_pull_secret
  }

  # ======================================================
  # ELASTICSEARCH/OPENSEARCH CONFIGURATION
  # ======================================================
  search_engine = {
    type                    = var.var_deploy_opensearch ? "opensearch" : "elasticsearch"
    deploy_opensearch       = var.var_deploy_opensearch
    deploy_elasticsearch    = var.var_deploy_elasticsearch
    mobius_elastic_enabled  = var.var_mobius_elastic_enabled
    mobius_elastic_host     = var.var_mobius_elastic_host
    mobius_elastic_port     = var.var_mobius_elastic_port
    fts_index_name          = var.var_mobius_fts_index_name
    opensearch_host         = var.var_opensearch_host
    opensearch_port         = var.var_opensearch_port
  }

  # ======================================================
  # SERVICE REPLICAS
  # ======================================================
  replicas = {
    mobius_server = var.var_mobius_server_replica
    mobius_view   = var.var_mobius_view_replica
    appmanager    = var.var_appmanager_replica
    studio        = var.var_studio_replica
    processengine = var.var_processengine_replica
  }

  # ======================================================
  # DEPLOYMENT FLAGS
  # ======================================================
  deployment_flags = {
    deploy_mobiusserver   = var.var_deploy_mobiusserver
    deploy_mobiusview     = var.var_deploy_mobiusview
    deploy_eventanalytics = var.var_deploy_eventanalytics
    deploy_appmanager     = var.var_deploy_appmanager
    deploy_studio         = var.var_deploy_studio
    deploy_processengine  = var.var_deploy_processengine
    deploy_nginx          = var.var_deploy_nginx
    deploy_opensearch     = var.var_deploy_opensearch
    deploy_smart_chat     = var.var_deploy_smart_chat
    deploy_elasticsearch  = var.var_deploy_elasticsearch
    deploy_postgresql     = var.var_deploy_postgresql
  }

  # ======================================================
  # KUBERNETES CONFIGURATION
  # ======================================================
  kubeconfig = {
    path    = var.var_kubeconfig_path
    context = var.var_kubeconfig_context != "" ? var.var_kubeconfig_context : null
    local   = var.var_use_localkube
  }

  # ======================================================
  # SERVICE ACCOUNTS
  # ======================================================
  service_accounts = {
    mobius        = var.var_mobius_service_account
    appmanager    = var.var_appmanager_service_account
    studio        = var.var_studio_service_account
    processengine = var.var_processengine_service_account
  }

  # ======================================================
  # PVC NAMES
  # ======================================================
  pvc_names = {
    mobius                      = var.var_mobius_pvc_name
    mobius_fts                  = var.var_mobius_fts_pvc_name
    mobius_diag                 = var.var_mobius_diag_pvc_name
    mobius_view                 = var.var_mobius_view_pvc_name
    mobius_view_diag            = var.var_mobius_view_diag_pvc_name
    mobius_view_presentation    = var.var_mobius_view_presentation_pvc_name
    appmanager                  = var.var_appmanager_pvc_name
    studio                      = var.var_studio_pvc_name
    processengine               = var.var_processengine_pvc_name
  }
}
