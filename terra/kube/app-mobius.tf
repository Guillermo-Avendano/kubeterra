# Deploy Mobius Server
resource "helm_release" "mobiusserver" {

  count      = var.var_deploy_mobiusserver == true ? 1 : 0
  depends_on = [
    null_resource.download_mobius_server_helm_chart,
    helm_release.postgresql,
    postgresql_database.postgres_schema_mobiusserver,
    kubernetes_secret.docker_registry_secret,
    kubernetes_persistent_volume_claim.mobius_pvc,
    kubernetes_persistent_volume_claim.mobius_fts_pvc,
    kubernetes_persistent_volume_claim.mobius_diagnostic_pvc,
    kubernetes_service_account.mobius_service_account,
    kubernetes_role.rocket_mobius_role,
    kubernetes_role_binding.rocket_mobius_role_binding,
    kubernetes_config_map.dbcert,
    kubernetes_config_map.cwallet
  ]

  name            = "mobius"
  chart           = "${path.root}/../charts/${var.var_mobiusserver_chart_file}"
  namespace       = var.var_namespace_mobius
  wait            = true
#  atomic          = true
#  cleanup_on_fail = true
#  upgrade_install = true
  values          = [
    <<-EOT
replicaCount: ${var.var_mobius_server_replica}
namespace: ${var.var_namespace_mobius}
image:
  repository: ${var.var_mobiusserver_docker_artifactory_url}
  tag: ${var.var_mobiusserver_image}
  pullPolicy: Always
  pullSecret: ${var.var_mobius_image_pull_secret}

mobius:
  clustering:
    port: 5701
    kubernetes:
      enabled: "${local.var_mobius_server_clustering_enabled}"
      namespace: ${var.var_namespace_mobius}

  admin:
    group: "mobiusadmin"
    user: "system"

  rds:
    protocol: "${local.var_database_protocol}"
    sslMode: "${var.var_database_sslmode}"
    provider: "${local.var_database_provider_upper}"
    endpoint: "${var.var_database_hostname}"
    port: "${var.var_database_port}"
    user: "${local.var_mobiusserver_database_user}"
    password: "${local.var_mobiusserver_database_password}"
    sid: ${var.var_database_oracle_sid}
    serviceName: ${var.var_database_oracle_service_name}
    schema: "${local.var_database_mobiusserver_schema}"
    password: "${local.var_mobiusserver_database_password}"
    initOrUpgrade: "YES"

  persistentVolume:
    enabled: ${local.var_mobius_pvc_enabled}
    claimName: "${var.var_mobius_pvc_name}"

  mobiusDiagnostics:
    persistentVolume:
      enabled: ${local.var_mobius_diag_pvc_enabled}
      claimName: "${var.var_mobius_diag_pvc_name}"

  createDocumentServer: "YES"
  isSaas: "YES"
  sharedFileTemplate: "${var.var_mobius_server_archive_file_path}"

  fts:
    enabled: "${local.var_mobius_fts_enabled}"
    persistentVolume:
      enabled: ${local.var_mobius_fts_pvc_enabled}
      claimName: "${var.var_mobius_fts_pvc_name}"
    engineType: "elasticsearch"
    serverProtocol: "HTTP"
    host: "${local.var_mobius_fts_host}"
    port: ${local.var_mobius_fts_port}
    indexName: "${var.var_mobius_fts_index_name}"

  defaultSSOKey: "ADASDFASDFXGGEG25585"

securityContext:
  runAsNonRoot: false

service:
  type: ClusterIP

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
