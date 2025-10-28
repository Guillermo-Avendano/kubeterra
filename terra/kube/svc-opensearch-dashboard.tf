# Deploy Open Search within the namesapce
resource "helm_release" "opensearch_dashboard" {

  count = var.var_deploy_opensearch == true && var.var_deploy_smart_chat == true ? 1 : 0

  name       = "opensearch-dashboards"
  repository = "opensearch"
  chart      = "opensearch-dashboards"
  version    = "2.15.1"
  namespace  = var.var_namespace_mobius
  timeout    = 600  # Extend timeout to 10 minutes since opensearch will take more than 5 mins (default timeout)

  values = [
    <<EOF

replicaCount: 1
startupProbe:
  periodSeconds: 10
  timeoutSeconds: 30
  failureThreshold: 30
  initialDelaySeconds: 180

service:
  type: NodePort

EOF
  ]
}

output "opensearch_dashboard_url" {

  description = "Opensearch dashboard URL"
  value = var.var_deploy_opensearch == true && var.var_deploy_smart_chat == true ? join("\n", [
    "",
    "Opensearch dashboard is also installed as Nodeport. Please use the below command to get Opensearch dashboard URL.",
    "",
    "export NODE_PORT=$(kubectl get -o jsonpath=\"{.spec.ports[0].nodePort}\" services opensearch-dashboards -n ${var.var_namespace_mobius})",
    "export NODE_IP=$(kubectl describe pod $(kubectl get pods -n ${var.var_namespace_mobius} --no-headers | grep opensearch-dashboards | awk '{print $1}') -n ${var.var_namespace_mobius} | grep \"Node:\" | cut -d'/' -f2)",
    "echo http://$NODE_IP:$NODE_PORT/",
    ""
  ]) : null
}

