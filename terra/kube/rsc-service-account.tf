# Create Service Account for Mobius Server and Mobius View
resource "kubernetes_service_account" "mobius_service_account" {

  count = (var.var_deploy_mobiusserver || var.var_deploy_mobiusview) == true ? 1 : 0
  metadata {
    name      = var.var_mobius_service_account
    namespace = var.var_namespace_mobius
    labels    = var.common_labels
  }
}

resource "kubernetes_service_account" "appmanager_service_account" {

  count = var.var_deploy_appmanager == true ? 1 : 0
  metadata {
    name      = var.var_appmanager_service_account
    namespace = var.var_namespace_mobius
    labels    = var.common_labels
  }
}

resource "kubernetes_service_account" "studio_service_account" {

  count = var.var_deploy_studio == true ? 1 : 0
  metadata {
    name      = var.var_studio_service_account
    namespace = var.var_namespace_mobius
    labels    = var.common_labels
  }
}

resource "kubernetes_service_account" "processengine_service_account" {

  count = var.var_deploy_processengine == true ? 1 : 0
  metadata {
    name      = var.var_processengine_service_account
    namespace = var.var_namespace_mobius
    labels    = var.common_labels
  }
}