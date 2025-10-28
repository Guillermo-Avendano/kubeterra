# Deploy Smart Chat
resource "helm_release" "smart_chat" {

  count      = var.var_deploy_smart_chat == true ? 1 : 0
  depends_on = [
    null_resource.download_smart_chat_helm_chart,
    kubernetes_secret.smart_chat_docker_registry_secret,
    kubernetes_secret.smart_chat_secrets
  ]

  name            = "smart-chat"
  chart           = "${path.root}/../charts/${var.var_smart_chat_chart_file}"
  namespace       = var.var_namespace_mobius
  timeout         = 600
  wait            = true
#  atomic          = true
#  cleanup_on_fail = true
#  upgrade_install = true
  values          = [
    <<-EOT
replicaCount: 1

image:
  repository: ${var.var_smart_chat_docker_artifactory_url}${var.var_smart_chat_service_name}
  pullPolicy: Always
  tag: ${var.var_smart_chat_image}

env:
  OPENSEARCH_HOST: ${var.var_opensearch_host}
  OPENSEARCH_PORT: ${var.var_opensearch_port}
  OPENSEARCH_USERNAME: ${var.var_opensearch_user}
  OPENSEARCH_PASSWORD: ${var.var_opensearch_password}
  OPENSEARCH_INDEX: ${var.var_mobius_fts_index_name}
  LOG_LEVEL: "DEBUG"
  #LLM_MODEL: "gpt-3.5-turbo"

imagePullSecrets:
  - name: ${var.var_smart_chat_image_pull_secret}

service:
  enabled: true
  type: ClusterIP
  port: 80
  podport: 8000
  clusterIP: null

sidecar_logger:
  name: smart-chat-query-logs
  image: 
    repository: ${var.var_smart_chat_query_logs_docker_artifactory_url}${var.var_smart_chat_query_logs_service_name}
    pullPolicy: Always
    tag: ${var.var_smart_chat_query_logs_image}  
    repository: registry.rocketsoftware.com/smart-chat-query-logs
    pullPolicy: IfNotPresent
    # Overrides the image tag whose default is the chart appVersion.
    tag: 1.2.2
  env:
    LOG_PATH: "/app/logs"
  resources:
    requests: 
      memory: 1Gi

    EOT
  ]
}
