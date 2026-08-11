# Deploy AppManager
resource "helm_release" "appmanager" {

  count      = var.var_deploy_appmanager == true ? 1 : 0
  depends_on = [
    null_resource.download_appmanager_helm_chart,
    postgresql_database.postgres_schema_appmanager,
    helm_release.postgresql,
    helm_release.processengine,
    kubernetes_secret.docker_registry_secret,
    kubernetes_persistent_volume_claim.appmanager_pvc,
    kubernetes_service_account.appmanager_service_account
  ]

  name      = "appmanager"
  chart     = "${path.root}/../helm_charts/${var.var_appmanager_chart_file}"
  namespace = var.var_namespace_mobius
  wait      = true

  values = [
    templatefile("${path.root}/../values/appmanager.yaml", {
      replicaCount = var.var_appmanager_replica
      namespace    = var.var_namespace_mobius
      image = {
        repository = var.var_appmanager_docker_artifactory_url
        tag        = var.var_appmanager_image
        pullSecret = var.var_mobius_image_pull_secret
      }
      spring = {
        datasource = {
          url             = local.var_appmanager_database_jdbc_url
          username        = local.var_appmanager_database_user
          password        = local.var_appmanager_database_password
          driverClassName = var.var_database_driver_class_name
        }
      }
      prs = {
        service = {
          processEngineService = var.var_processengine_service_name
          mobiusViewService    = var.var_mobius_view_service_name
        }
      }
      persistence = {
        enabled   = local.var_appmanager_pvc_enabled
        claimName = var.var_appmanager_pvc_name
      }
      asg = {
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
