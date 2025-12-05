# Create Docker Registry Secret for Mobius Server, Mobius View and Event Analytics
resource "kubernetes_secret" "docker_registry_secret" {

  count = (var.var_deploy_mobiusserver || var.var_deploy_mobiusview || var.var_deploy_eventanalytics) == true ? 1 : 0
  metadata {
    name      = var.var_mobius_image_pull_secret
    namespace = var.var_namespace_mobius
    labels    = var.common_labels
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.var_mobius_docker_registry}" = {
          "username" = var.var_docker_username
          "password" = var.var_docker_password
          "email"    = var.var_docker_email
          "auth"     = base64encode("${var.var_docker_username}:${var.var_docker_password}")
        }
      }
    })
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
    license = var.var_mobius_license
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
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.var_smart_chat_docker_registry}" = {
          "username" = var.var_docker_username
          "password" = var.var_docker_password
          "email"    = var.var_docker_email
          "auth"     = base64encode("${var.var_docker_username}:${var.var_docker_password}")
        }
      }
    })
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
    OPENAI_API_KEY = var.var_smart_chat_openai_api_key
  }

  type = "Opaque"
}