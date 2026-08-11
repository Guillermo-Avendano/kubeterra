# Deploy Studio
resource "helm_release" "studio" {

  count      = var.var_deploy_studio == true ? 1 : 0
  depends_on = [
    null_resource.download_studio_helm_chart,
    postgresql_database.postgres_schema_studio,
    helm_release.postgresql,
    helm_release.processengine,
    helm_release.appmanager,
    kubernetes_secret.docker_registry_secret,
    kubernetes_persistent_volume_claim.studio_pvc,
    kubernetes_service_account.studio_service_account
  ]

  name      = "studio"
  chart     = "${path.root}/../helm_charts/${var.var_studio_chart_file}"
  namespace = var.var_namespace_mobius
  wait      = true

  values = [
    templatefile("${path.root}/../values/studio.yaml", {
      replicaCount = var.var_studio_replica
      namespace    = var.var_namespace_mobius
      image = {
        repository = var.var_studio_docker_artifactory_url
        tag        = var.var_studio_image
        pullSecret = var.var_mobius_image_pull_secret
      }
      spring = {
        datasource = {
          url             = local.var_studio_database_jdbc_url
          username        = local.var_studio_database_user
          password        = local.var_studio_database_password
          driverClassName = var.var_database_driver_class_name
        }
      }
      services = {
        appmanager   = var.var_appmanager_service_name
        processengine = var.var_processengine_service_name
        mobiusview   = var.var_mobius_view_service_name
      }
      studio = {
        templateName      = var.var_studio_template_display_name
        templateLocalPath = var.var_studio_template_local_path
      }
      persistence = {
        enabled   = local.var_studio_pvc_enabled
        claimName = var.var_studio_pvc_name
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
