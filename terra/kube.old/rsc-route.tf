## To create Openshift Route for Mobius View
#resource "kubernetes_manifest" "tf_mobius_route" {
#
#  count = var.var_deploy_mobiusview == true ? 1 : 0
#  depends_on = [
#    helm_release.tf_mobiusview
#  ]
#
#  manifest = {
#    apiVersion = "route.openshift.io/v1"
#    kind       = "Route"
#    metadata   = {
#      name      = "mobius-route"
#      namespace = var.var_namespace_mobius
#      labels    = var.common_labels
#    }
#    spec = {
#      to = {
#        kind   = "Service"
#        name   = "mobiusview"
#        weight = 100
#      }
#      port = {
#        targetPort = "http"
#      }
#      wildcardPolicy = "None"
#    }
#  }
#}
#
#### To Print the Mobius View URL to the console in a pretty multiline format
#output "mobius_route_url" {
#  description = "Mobius View access URL"
#  value = length(kubernetes_manifest.tf_mobius_route) > 0 && can(kubernetes_manifest.tf_mobius_route[0].object["spec"]["host"]) ? join("\n", [
#    "",
#    "You have successfully deployed the Mobius Stack in OpenShift. Please use the below URL to access Mobius View.",
#    "http://${kubernetes_manifest.tf_mobius_route[0].object["spec"]["host"]}/mobius/",
#    ""
#  ]) : null
#}
#
#
