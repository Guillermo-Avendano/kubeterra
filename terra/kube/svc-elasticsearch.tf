# Deploy Elastic Search for Full Text Search if Smart Chat is disabled
resource "helm_release" "elasticsearch" {

  count      = var.var_deploy_elasticsearch == true && var.var_deploy_smart_chat == false ? 1 : 0

  name       = "elasticsearch"
  repository = "https://helm.elastic.co"
  chart      = "elasticsearch"
  version    = "8.5.1"
  namespace = var.var_namespace_mobius
  timeout = 600  # Extend timeout to 10 minutes since elastic will take more than 5 mins (default timeout)

  values = [
    templatefile("${path.root}/../values/elasticsearch.yaml", {
      image = {
        repository = "docker.elastic.co/elasticsearch/elasticsearch"
        tag        = "8.5.1"
      }
    })
  ]
}
