# Deploy Open Search within the namesapce
resource "helm_release" "opensearch" {

  count      = var.var_deploy_opensearch == true && var.var_deploy_smart_chat == true ? 1 : 0

  name       = "opensearch"
  repository = "opensearch"
  #repository = "https://opensearch-project.github.io/helm-charts/"
  chart      = "opensearch"
  version    = "2.18.0"
  namespace = var.var_namespace_mobius
  timeout = 600  # Extend timeout to 10 minutes since opensearch will take more than 5 mins (default timeout)

  values = [
    templatefile("${path.root}/../values/opensearch.yaml", {
      image = {
        repository = "opensearchproject/opensearch"
        tag        = "2.12.0"
      }
      extraEnvs = {
        OPENSEARCH_INITIAL_ADMIN_PASSWORD = var.var_opensearch_password
      }
    })
  ]
}
