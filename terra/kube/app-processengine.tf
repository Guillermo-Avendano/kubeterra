# Deploy ProcessEngine
resource "helm_release" "processengine" {

  count      = var.var_deploy_processengine == true ? 1 : 0
  depends_on = [
    null_resource.download_processengine_helm_chart,
    postgresql_database.postgres_schema_processengine_flowable,
    postgresql_database.postgres_schema_processengine_root,
    helm_release.postgresql,
    kubernetes_secret.docker_registry_secret,
    kubernetes_persistent_volume_claim.processengine_pvc,
    kubernetes_service_account.processengine_service_account
  ]

  name      = "processengine"
  chart     = "${path.root}/../helm_charts/${var.var_processengine_chart_file}"
  namespace = var.var_namespace_mobius
  wait      = true

  values = [
    templatefile("${path.root}/../values/processengine.yaml", {
      replicaCount = var.var_processengine_replica
      namespace    = var.var_namespace_mobius
      image = {
        repository = var.var_processengine_docker_artifactory_url
        tag        = var.var_processengine_image
        pullSecret = var.var_mobius_image_pull_secret
      }
      spring = {
        datasource = {
          flowable = {
            url      = local.var_processengine_flowable_database_jdbc_url
            username = local.var_processengine_flowable_database_user
            password = local.var_processengine_flowable_database_password
          }
          root = {
            url      = local.var_processengine_root_database_jdbc_url
            username = local.var_processengine_root_database_user
            password = local.var_processengine_root_database_password
          }
        }
      }
      services = {
        appmanager   = var.var_appmanager_service_name
        studio       = var.var_studio_service_name
        mobiusview   = var.var_mobius_view_service_name
        processengine = var.var_processengine_service_name
      }
      persistence = {
        mountName   = var.var_processengine_mount_name
        storagePath = var.var_processengine_storage_path
        targetPath  = var.var_processengine_target_path
        claimName   = var.var_processengine_pvc_name
      }
      flowable = {
        mail = {
          host        = var.var_process_mail_host
          defaultFrom = var.var_process_mail_from_email
          username    = var.var_process_mail_username
          password    = var.var_process_mail_password
        }
      }
      asg = {
        iam = {
          ldap = {
            enabled = var.var_processengine_ldap_enabled
          }
        }
        processengine = {
          agent = {
            enabled       = var.var_processengine_agent_task_enabled
            openaiApiKey  = var.var_processengine_openai_api_key
            mcpServerName = var.var_mcp_server_name
            mcpServerUrl  = var.var_mcp_server_url
            mcpServerPath = var.var_mcp_server_path
          }
        }
        security = {
          jwt = {
            privateKey = var.var_jwt_private_key
            publicKey  = var.var_jwt_public_key
          }
        }
      }
    })
  ]
}
