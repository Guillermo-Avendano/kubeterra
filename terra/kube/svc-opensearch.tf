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
    <<EOF
replicas: 1

image:
  repository: "opensearchproject/opensearch"
  tag: "2.12.0"
  pullPolicy: "IfNotPresent"

# Permit co-located instances for solitary  virtual machines.
antiAffinity: "soft"

protocol: https
httpPort: 9200
transportPort: 9300
opensearchJavaOpts: "-Xmx512m -Xms512m"

startupProbe:
  initialDelaySeconds: 10
  periodSeconds: 10
  timeoutSeconds: 30
  failureThreshold: 30

persistence:
  enabled: false
  accessModes:
    - ReadWriteOnce
  storageClass: "manual"
  size: 1000M

service:
  type: NodePort

extraEnvs:
 - name: discovery.type
   value: single-node
 - name: cluster.initial_master_nodes
   value: null
 - name: OPENSEARCH_INITIAL_ADMIN_PASSWORD
   value: ${var.var_opensearch_password}

EOF
  ]
}
