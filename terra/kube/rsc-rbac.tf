# Deploy Role and RoleBinding (RBAC) in Openshift when clustering is enabled
resource "kubernetes_role" "rocket_mobius_role" {

  count = (
  local.var_mobius_server_clustering_enabled == "TRUE" || local.var_mobius_view_clustering_enabled == true
  ) ? 1 : 0

  metadata {
    name      = "rocket_mobius_role"
    namespace = var.var_namespace_mobius
    labels    = var.common_labels
  }

  rule {
    api_groups = [""]
    resources  = ["endpoints", "pods", "services"]
    verbs      = ["get", "list"]
  }
}

resource "kubernetes_role_binding" "rocket_mobius_role_binding" {

  count = (
  local.var_mobius_server_clustering_enabled == "TRUE" || local.var_mobius_view_clustering_enabled == true
  ) ? 1 : 0

  depends_on = [
    kubernetes_role.rocket_mobius_role
  ]
  metadata {
    name      = "rocket_mobius_role_binding"
    namespace = var.var_namespace_mobius
    labels    = var.common_labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.rocket_mobius_role[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = var.var_mobius_service_account
    namespace = var.var_namespace_mobius
  }
}