# Deploy Event Analytics aka Content Insight
resource "helm_release" "eventanalytics" {

  count      = var.var_deploy_eventanalytics == true ? 1 : 0
  depends_on = [
    null_resource.download_eventanalytics_helm_chart,
    postgresql_database.postgres_schema_eventanalytics,
    helm_release.postgresql,
    kubernetes_stateful_set.kafka
  ]
  name            = "eventanalytics"
  chart           = "${path.root}/../charts/${var.var_eventanalytics_chart_file}"
  namespace       = var.var_namespace_mobius
  wait            = true
#  atomic          = true
#  cleanup_on_fail = true
#  upgrade_install = true
  values          = [
    <<-EOT
replicaCount: 1
namespace: ${var.var_namespace_mobius}
image:
  repository: ${var.var_eventanalytics_docker_artifactory_url}${var.var_eventanalytics_service_name}
  tag: ${var.var_eventanalytics_image}
  pullPolicy: Always

datasource:
  url: "${local.var_eventanalytics_database_jdbc_url}"
  username: ${local.var_eventanalytics_database_user}
  password: ${local.var_eventanalytics_database_password}
  driverClassName: ${var.var_database_driver_class_name}

spring:
  kafka:
    bootstrap:
      servers: kafka.${var.var_namespace_mobius}.svc.cluster.local:9092

securityContext:
  runAsNonRoot: false

    EOT
  ]
}
