# Create PVC for Mobius Server
resource "kubernetes_persistent_volume_claim" "mobius_pvc" {

  count      = (var.var_deploy_mobiusserver && local.var_mobius_pvc_enabled) == true ? 1 : 0
  metadata {
    name      = var.var_mobius_pvc_name
    namespace = var.var_namespace_mobius
    labels    = var.common_labels
  }

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = var.var_pvc_storage_class
    resources {
      requests = {
        storage = var.var_pvc_storage_capacity
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "mobius_fts_pvc" {

  count = (var.var_deploy_mobiusserver && local.var_mobius_fts_pvc_enabled) == true ? 1 : 0
  metadata {
    name      = var.var_mobius_fts_pvc_name
    namespace = var.var_namespace_mobius
    labels    = var.common_labels
  }

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = var.var_pvc_storage_class
    resources {
      requests = {
        storage = var.var_pvc_storage_capacity
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "mobius_diagnostic_pvc" {

  count = (var.var_deploy_mobiusserver && local.var_mobius_diag_pvc_enabled) == true ? 1 : 0
  metadata {
    name      = var.var_mobius_diag_pvc_name
    namespace = var.var_namespace_mobius
    labels    = var.common_labels
  }

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = var.var_pvc_storage_class
    resources {
      requests = {
        storage = var.var_pvc_storage_capacity
      }
    }
  }
}

# Create PVC for Mobius View
resource "kubernetes_persistent_volume_claim" "mobiusview_pvc" {

  count = (var.var_deploy_mobiusview && local.var_mobius_view_pvc_enabled) == true ? 1 : 0

  metadata {
    name      = var.var_mobius_view_pvc_name
    namespace = var.var_namespace_mobius
    labels    = var.common_labels
  }

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = var.var_pvc_storage_class
    resources {
      requests = {
        storage = var.var_pvc_storage_capacity
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "mobiusview_diagnostic_pvc" {

  count = (var.var_deploy_mobiusview && local.var_mobius_view_diag_pvc_enabled) ? 1 : 0
  metadata {
    name      = var.var_mobius_view_diag_pvc_name
    namespace = var.var_namespace_mobius
    labels    = var.common_labels
  }

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = var.var_pvc_storage_class
    resources {
      requests = {
        storage = var.var_pvc_storage_capacity
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "mobiusview_presentation_pvc" {

  count = (var.var_deploy_mobiusview && local.var_mobius_view_presentaion_pvc_enabled) == true ? 1 : 0
  metadata {
    name      = var.var_mobius_view_presentation_pvc_name
    namespace = var.var_namespace_mobius
    labels    = var.common_labels
  }

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = var.var_pvc_storage_class
    resources {
      requests = {
        storage = var.var_pvc_storage_capacity
      }
    }
  }
}
