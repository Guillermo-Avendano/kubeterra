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
    <<-EOT
replicaCount: ${var.var_mobius_view_replica}
namespace: ${var.var_namespace_mobius}
image:
  repository: ${var.var_mobiusview_docker_artifactory_url}mobius-view
  tag: "${var.var_mobiusview_image}"
  pullPolicy: Always
  pullSecret: "${var.var_mobius_image_pull_secret}"

asg:
  clustering:
    port: 6701
    kubernetes:
      enabled: ${local.var_mobius_view_clustering_enabled}
      namespace: ${var.var_namespace_mobius}
  audit:
    topic: audit
  smartchat:
    initconfig: ${var.var_deploy_smart_chat}
    url: http://${var.var_smart_chat_service_name}:80

deploy:
  fullstack: false

service:
  type: NodePort

datasource:
  url: "${local.var_mobiusview_database_jdbc_url}"
  username: "${local.var_mobiusview_database_user}"
  password: "${local.var_mobiusview_database_password}"
  driverClassName: ${var.var_database_driver_class_name}
jpa:
  databasePlatform: ${var.var_database_platform}

initRepository:
  enabled: true
  host: "${local.var_mobius_server_init_host}"
  port: "${local.var_mobius_server_init_port}"
  documentServer: "vdrnetds"
  defaultSSOKey: "ADASDFASDFXGGEG25585"
  logLevel: "ERROR"
  java:
    opts: ""

master:
  persistence:
    enabled: ${local.var_mobius_view_pvc_enabled}
    claimName: "${var.var_mobius_view_pvc_name}"
    accessMode: ReadWriteMany
    size: 1000M

  mobiusViewDiagnostics:
    persistentVolume:
      enabled: ${local.var_mobius_view_diag_pvc_enabled}
      claimName: ${var.var_mobius_view_diag_pvc_name}
      accessMode: ReadWriteMany
      size: 1000M

  presentations:
    persistence:
      enabled: ${local.var_mobius_view_presentaion_pvc_enabled}
      claimName: ${var.var_mobius_view_presentation_pvc_name}

spring:
  kafka:
    bootstrap:
      servers: kafka.${var.var_namespace_mobius}.svc.cluster.local:9092
    security:
      protocol: PLAINTEXT
    producer:
      acks: all
      properties:
        enable:
          idempotence: true

  cloud:
    discovery:
      client:
        simple:
          instances:
            metrics:
              audit:
                uri: http://eventanalyics:8500

securityContext:
  runAsNonRoot: false

serviceAccount:
  name: ${var.var_mobius_service_account}

#resources:
#  limits:
#    cpu: 100m
#    memory: 128Mi
#  requests:
#    cpu: 100m
#    memory: 128Mi

## Uncomment below to use SSL certificate for database
#additionalVolumes:
#  - name: dbcert
#    configMap:
#      name: dbcert
## Uncomment below for Oracle to connect with SSL
#  - name: cwallet
#    configMap:
#      name: cwallet
#
## Uncomment below to use SSL certificate for database
#additionalVolumeMounts:
#  - name: dbcert
#    mountPath: /etc/pki/tls/custom/database-root-certificate.crt
#    subPath: database-root-certificate.crt
#    readOnly: false
## Uncomment below for Oracle to connect with SSL
#  - name: cwallet
#    mountPath: /mnt/efs/ssl_wallet/cwallet.sso
#    subPath: cwallet.sso
#    readOnly: false

    EOT
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
