# Config map to mount database certificate
resource "kubernetes_config_map" "dbcert" {

  count = local.var_database_ssl_enabled == true ? 1 : 0
  metadata {
    name      = "dbcert"
    namespace = var.var_namespace_mobius
    labels    = var.common_labels
  }

  binary_data = {
    "database-root-certificate.crt" = filebase64("${path.root}/../certs/database-root-certificate.crt")
  }
}

# Config map to mount oracle sso wallet
resource "kubernetes_config_map" "cwallet" {

  count = (local.var_database_ssl_enabled && upper(var.var_database_provider) == "ORACLE") ? 1 : 0
  metadata {
    name      = "cwallet"
    namespace = var.var_namespace_mobius
    labels    = var.common_labels
  }

  binary_data = {
    "cwallet.sso" = filebase64("${path.root}/../certs/cwallet.sso")
  }
}