# Create Docker Registry Secret for Mobius Server, Mobius View and Event Analytics
resource "kubernetes_secret" "docker_registry_secret" {

  count = (var.var_deploy_mobiusserver || var.var_deploy_mobiusview || var.var_deploy_eventanalytics) == true ? 1 : 0
  metadata {
    name      = var.var_mobius_image_pull_secret
    namespace = var.var_namespace_mobius
    labels    = var.common_labels
  }

  type = "kubernetes.io/dockerconfigjson"

  # data expects base64-encoded strings; encode the JSON docker config
  data = {
    ".dockerconfigjson" = base64encode(jsonencode({
      auths = {
        "${var.var_mobius_docker_registry}" = {
          "username" = var.var_docker_username
          "password" = var.var_docker_password
          "email"    = var.var_docker_email
          "auth"     = base64encode("${var.var_docker_username}:${var.var_docker_password}")
        }
      }
    }))
  }
}

# Create Mobius License Secret
resource "kubernetes_secret" "mobius_license" {

  count = var.var_deploy_mobiusview == true ? 1 : 0
  type  = "Opaque"

  metadata {
    name      = "mobius-license"
    namespace = var.var_namespace_mobius
    labels    = var.common_labels
  }

  data = {
    license = base64encode(var.var_mobius_license)
  }
}

# Create Docker Registry Secret for Smart Chat
resource "kubernetes_secret" "smart_chat_docker_registry_secret" {

  count = var.var_deploy_smart_chat == true ? 1 : 0
  metadata {
    name      = "smartchatdockerlocal"
    namespace = var.var_namespace_mobius
    labels    = var.common_labels
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = base64encode(jsonencode({
      auths = {
        "${var.var_smart_chat_docker_registry}" = {
          "username" = var.var_docker_username
          "password" = var.var_docker_password
          "email"    = var.var_docker_email
          "auth"     = base64encode("${var.var_docker_username}:${var.var_docker_password}")
        }
      }
    }))
  }
}

# Create Open AI Key Secret
resource "kubernetes_secret" "smart_chat_secrets" {

  count = var.var_deploy_smart_chat == true ? 1 : 0
  metadata {
    name      = "smart-chat-secrets"
    namespace = var.var_namespace_mobius
    labels    = var.common_labels
  }

  data = {
    OPENAI_API_KEY = base64encode(var.var_smart_chat_openai_api_key)
  }

  type = "Opaque"
}

# Create PostgreSQL Password Secret
resource "kubernetes_secret" "postgresql_secret" {

  count = var.var_deploy_postgresql == true ? 1 : 0
  metadata {
    name      = "postgresql"
    namespace = var.var_namespace_mobius
    labels    = var.common_labels
  }

  data = {
    postgres-password = base64encode(var.var_database_password)
    password          = base64encode(var.var_database_password)
  }

  type = "Opaque"
}