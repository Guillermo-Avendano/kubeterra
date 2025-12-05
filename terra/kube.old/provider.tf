provider "kubernetes" {
  config_path    = var.var_kubeconfig_path
  config_context = var.var_kubeconfig_context != "" ? var.var_kubeconfig_context : null
}

provider "helm" {
  kubernetes = {
    config_path    = var.var_kubeconfig_path
    config_context = var.var_kubeconfig_context != "" ? var.var_kubeconfig_context : null
  }
}
