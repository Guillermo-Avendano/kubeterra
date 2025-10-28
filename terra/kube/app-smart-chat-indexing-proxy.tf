# Deploy Smart Chat Indexing Proxy
resource "helm_release" "smart_chat_indexing_proxy" {

  count      = var.var_deploy_smart_chat == true ? 1 : 0
  depends_on = [
    null_resource.download_smart_chat_indexing_proxy_helm_chart,
    helm_release.smart_chat
  ]

  name            = "smart-chat-indexing-proxy"
  chart           = "${path.root}/../charts/${var.var_smart_chat_indexing_proxy_chart_file}"
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
  repository: ${var.var_smart_chat_docker_artifactory_url}${var.var_smart_chat_indexing_proxy_service_name}
  pullPolicy: Always
  tag: ${var.var_smart_chat_indexing_proxy_image}

imagePullSecrets:
  - name: ${var.var_smart_chat_image_pull_secret}

    EOT
  ]
}
