# Deploy Mobius View
resource "helm_release" "mobiusview" {

  count      = var.var_deploy_mobiusview == true ? 1 : 0
  depends_on = [
    null_resource.download_mobius_view_helm_chart,
    helm_release.postgresql,
    postgresql_database.postgres_schema_mobiusview,
    kubernetes_secret.docker_registry_secret,
    kubernetes_persistent_volume_claim.mobiusview_pvc,
    kubernetes_persistent_volume_claim.mobiusview_diagnostic_pvc,
    kubernetes_persistent_volume_claim.mobiusview_presentation_pvc,
    kubernetes_service_account.mobius_service_account,
    kubernetes_role.rocket_mobius_role,
    kubernetes_role_binding.rocket_mobius_role_binding,
    helm_release.smart_chat_indexing_proxy,
    helm_release.smart_chat,
    helm_release.mobiusserver
  ]

  name            = "mobiusview"
  chart           = "${path.root}/../charts/${var.var_mobiusview_chart_file}"
  namespace       = var.var_namespace_mobius
  wait            = true
#  atomic          = true
#  cleanup_on_fail = true
#  upgrade_install = true
  values          = [
    templatefile("${path.root}/../values/mobiusview.yaml", {
      replicaCount = var.var_mobius_view_replica
      namespace    = var.var_namespace_mobius
      image = {
        repository  = var.var_mobiusview_docker_artifactory_url
        tag         = var.var_mobiusview_image
        pullSecret  = var.var_mobius_image_pull_secret
      }
      asg = {
        clustering = {
          kubernetes = {
            enabled = local.var_mobius_view_clustering_enabled
          }
        }
        smartchat = {
          initconfig = var.var_deploy_smart_chat
          url        = var.var_smart_chat_service_name
        }
      }
      datasource = {
        url              = local.var_mobiusview_database_jdbc_url
        username         = local.var_mobiusview_database_user
        password         = local.var_mobiusview_database_password
        driverClassName  = var.var_database_driver_class_name
      }
      jpa = {
        databasePlatform = var.var_database_platform
      }
      initRepository = {
        host = local.var_mobius_server_init_host
        port = local.var_mobius_server_init_port
      }
      master = {
        persistence = {
          enabled   = local.var_mobius_view_pvc_enabled
          claimName = var.var_mobius_view_pvc_name
        }
        mobiusViewDiagnostics = {
          persistentVolume = {
            enabled   = local.var_mobius_view_diag_pvc_enabled
            claimName = var.var_mobius_view_diag_pvc_name
          }
        }
        presentations = {
          persistence = {
            enabled   = local.var_mobius_view_presentaion_pvc_enabled
            claimName = var.var_mobius_view_presentation_pvc_name
          }
        }
      }
    })
  ]
}

### To Print the Mobius View URL to the console in a pretty multiline format
output "mobius_view_url" {
  description = "Mobius View access URL"
  value = var.var_deploy_mobiusview ? join("\n", [
    "",
    "You have successfully deployed the Mobius Stack in Kube. Please use the below command to get Mobius View URL.",
    "",
    "for pod in $(kubectl get pods -o name -n ${var.var_namespace_mobius} | grep mobiusview); do NODE_PORT=$(kubectl get -o jsonpath=\"{.spec.ports[0].nodePort}\" services mobiusview -n ${var.var_namespace_mobius}); NODE_IP=$(kubectl describe $pod -n ${var.var_namespace_mobius} | grep \"Node:\" | cut -d'/' -f2 | awk '{print $1}'); echo \"http://$NODE_IP:$NODE_PORT/mobius/\"; done",
    ""
  ]) : null
}
