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
    templatefile("${path.root}/../values/smart_chat.yaml", {
      namespace = var.var_namespace_mobius
      image = {
        repository = var.var_smart_chat_docker_artifactory_url
        tag        = var.var_smart_chat_image
      }
      env = {
        OPENSEARCH_HOST     = var.var_opensearch_host
        OPENSEARCH_PORT     = var.var_opensearch_port
        OPENSEARCH_USERNAME = var.var_opensearch_user
        OPENSEARCH_PASSWORD = var.var_opensearch_password
        OPENSEARCH_INDEX    = var.var_mobius_fts_index_name
        QUERY_ROUTER_ENABLED = "false"
        QUERY_OPTIMIZATION  = "false"
        WORKERS             = "1"
      }
      imagePullSecrets = {
        name = var.var_smart_chat_image_pull_secret
      }
      sidecar_logger = {
        image = {
          repository = var.var_smart_chat_query_logs_docker_artifactory_url
          tag        = var.var_smart_chat_query_logs_image
        }
      }
    })
  ]
}
