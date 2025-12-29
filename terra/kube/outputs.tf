# ======================================================
# Terraform Outputs
# ======================================================
# This file defines the output values after deployment
# These values are displayed after terraform apply

output "deployment_summary" {
  description = "Summary of deployed services and configuration"
  value = {
    namespace              = var.var_namespace_mobius
    kubernetes_provider    = var.var_database_provider
    use_local_kube         = var.var_use_localkube
    kubeconfig_context     = var.var_kubeconfig_context != "" ? var.var_kubeconfig_context : "default"
  }
}

output "deployed_services" {
  description = "Status of deployed services"
  value = {
    mobius_server   = var.var_deploy_mobiusserver ? "Deployed" : "Skipped"
    mobius_view     = var.var_deploy_mobiusview ? "Deployed" : "Skipped"
    event_analytics = var.var_deploy_eventanalytics ? "Deployed" : "Skipped"
    opensearch      = var.var_deploy_opensearch ? "Deployed" : "Skipped"
    smart_chat      = var.var_deploy_smart_chat ? "Deployed" : "Skipped"
    elasticsearch   = var.var_deploy_elasticsearch ? "Deployed" : "Skipped"
    postgresql      = var.var_deploy_postgresql ? "Deployed" : "Skipped"
  }
}

output "kubernetes_configuration" {
  description = "Kubernetes deployment configuration"
  value = {
    namespace             = var.var_namespace_mobius
    pvc_enabled           = var.var_pvc_enabled
    pvc_storage_class     = var.var_pvc_storage_class
    service_account       = var.var_mobius_service_account
  }
}

output "database_configuration" {
  description = "Database connection information"
  value = {
    provider   = var.var_database_provider
    hostname   = var.var_database_hostname
    port       = var.var_database_port
    user       = var.var_database_user
    driver     = var.var_database_driver_class_name
    platform   = var.var_database_platform
    sslmode    = try(var.var_database_sslmode, "default")
  }
  sensitive = false  # Set to false as it contains no actual passwords
}

output "database_schemas" {
  description = "Database schemas created for applications"
  value = {
    mobius_server   = var.var_database_mobiusserver_schema
    mobius_view     = var.var_database_mobiusview_schema
    event_analytics = var.var_database_eventanalytics_schema
  }
}

output "image_registry_configuration" {
  description = "Docker image registry URLs"
  value = {
    mobius_server   = var.var_mobiusserver_docker_artifactory_url
    mobius_view     = var.var_mobiusview_docker_artifactory_url
    event_analytics = var.var_eventanalytics_docker_artifactory_url
    smart_chat      = var.var_smart_chat_docker_artifactory_url
    smart_chat_indexing_proxy = var.var_smart_chat_indexing_proxy_docker_artifactory_url
    smart_chat_query_logs     = var.var_smart_chat_query_logs_docker_artifactory_url
  }
}

output "image_versions" {
  description = "Deployed image versions"
  value = {
    mobius_server   = var.var_mobiusserver_image
    mobius_view     = var.var_mobiusview_image
    event_analytics = var.var_eventanalytics_image
    smart_chat      = var.var_smart_chat_image
    smart_chat_indexing_proxy = var.var_smart_chat_indexing_proxy_image
    smart_chat_query_logs     = var.var_smart_chat_query_logs_image
  }
}

output "helm_charts" {
  description = "Helm charts used for deployment"
  value = {
    mobius_server   = var.var_mobiusserver_chart_file
    mobius_view     = var.var_mobiusview_chart_file
    event_analytics = var.var_eventanalytics_chart_file
    smart_chat      = var.var_smart_chat_chart_file
    smart_chat_indexing_proxy = var.var_smart_chat_indexing_proxy_chart_file
  }
}

output "replicas" {
  description = "Pod replica counts"
  value = {
    mobius_server = var.var_mobius_server_replica
    mobius_view   = var.var_mobius_view_replica
  }
}

output "opensearch_configuration" {
  description = "OpenSearch cluster configuration"
  value = {
    host            = var.var_opensearch_host
    port            = var.var_opensearch_port
    user            = var.var_opensearch_user
  }
  sensitive = false
}

output "elasticsearch_configuration" {
  description = "Elasticsearch configuration for Mobius"
  value = {
    enabled       = var.var_mobius_elastic_enabled
    host          = var.var_mobius_elastic_host
    port          = var.var_mobius_elastic_port
    fts_index     = var.var_mobius_fts_index_name
  }
}

output "storage_configuration" {
  description = "Storage and PVC configuration"
  value = {
    pvc_enabled              = var.var_pvc_enabled
    pvc_storage_class        = var.var_pvc_storage_class
    mobius_pvc               = var.var_mobius_pvc_name
    mobius_fts_pvc           = var.var_mobius_fts_pvc_name
    mobius_diag_pvc          = var.var_mobius_diag_pvc_name
    mobius_view_pvc          = var.var_mobius_view_pvc_name
    mobius_view_diag_pvc     = var.var_mobius_view_diag_pvc_name
    mobius_view_presentation_pvc = var.var_mobius_view_presentation_pvc_name
    archive_file_path        = var.var_mobius_server_archive_file_path
  }
}

output "image_pull_secrets" {
  description = "Image pull secrets for private registries"
  value = {
    mobius    = var.var_mobius_image_pull_secret
    smart_chat = var.var_smart_chat_image_pull_secret
  }
}

output "deployment_notes" {
  description = "Important notes and next steps"
  value = <<-EOT
    Deployment Summary:
    ==================
    
    Namespace: ${var.var_namespace_mobius}
    
    Useful Commands:
    - View pod status: kubectl get pods -n ${var.var_namespace_mobius}
    - View services: kubectl get svc -n ${var.var_namespace_mobius}
    - View deployments: kubectl get deployments -n ${var.var_namespace_mobius}
    - View helm releases: helm list -n ${var.var_namespace_mobius}
    - Check logs: kubectl logs -n ${var.var_namespace_mobius} <pod-name>
    
    To destroy all resources (CAUTION):
    - terraform destroy -auto-approve
    
    For more information, see terra/kube/readme.MD
  EOT
}

output "labels" {
  description = "Common labels applied to all resources"
  value       = var.common_labels
}
