# Create Service Account for Mobius Server and Mobius View
resource "kubernetes_service_account" "mobius_service_account" {

  count = (var.var_deploy_mobiusserver || var.var_deploy_mobiusview) == true ? 1 : 0
  metadata {
    name      = var.var_mobius_service_account
    namespace = var.var_namespace_mobius
    labels    = var.common_labels
  }
}