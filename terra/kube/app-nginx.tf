# Deploy external NGINX ingress controller and core ingress routes
resource "kubernetes_namespace" "nginx_namespace" {
  count = var.var_deploy_nginx ? 1 : 0

  metadata {
    name   = var.var_nginx_namespace
    labels = var.common_labels
  }
}

resource "helm_release" "nginx_external" {
  count = var.var_deploy_nginx ? 1 : 0

  depends_on = [
    kubernetes_namespace.nginx_namespace,
    helm_release.mobiusview,
    helm_release.appmanager,
    helm_release.processengine,
    helm_release.studio
  ]

  name       = "nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.var_nginx_chart_version
  namespace  = var.var_nginx_namespace
  wait       = true

  values = [
    templatefile("${path.root}/../values/nginx.yaml", {
      nginxVersion = var.var_nginx_version
      namespace    = var.var_namespace_mobius
    })
  ]
}

resource "kubernetes_ingress_v1" "mobiusview_ingress" {
  count = var.var_deploy_nginx && var.var_deploy_mobiusview ? 1 : 0

  depends_on = [helm_release.nginx_external, helm_release.mobiusview]

  metadata {
    name      = "mobiusingress"
    namespace = var.var_namespace_mobius
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    rule {
      host = var.var_ingress_hostname
      http {
        path {
          path      = "/mobius/"
          path_type = "Prefix"
          backend {
            service {
              name = var.var_mobius_view_service_name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "appmanager_ingress" {
  count = var.var_deploy_nginx && var.var_deploy_appmanager ? 1 : 0

  depends_on = [helm_release.nginx_external, helm_release.appmanager]

  metadata {
    name      = "contentautomation-appmanager-ingress"
    namespace = var.var_namespace_mobius
    annotations = {
      "kubernetes.io/ingress.class"                         = "nginx"
      "nginx.ingress.kubernetes.io/proxy-read-timeout"     = "86400"
      "nginx.ingress.kubernetes.io/proxy-send-timeout"     = "86400"
      "nginx.ingress.kubernetes.io/proxy-body-size"        = "100m"
    }
  }

  spec {
    rule {
      host = var.var_ingress_hostname
      http {
        path {
          path      = "/contentautomation"
          path_type = "Prefix"
          backend {
            service {
              name = var.var_appmanager_service_name
              port {
                number = 8521
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "appmanager_auth_ingress" {
  count = var.var_deploy_nginx && var.var_deploy_appmanager ? 1 : 0

  depends_on = [helm_release.nginx_external, helm_release.appmanager]

  metadata {
    name      = "contentautomation-authorization-ingress"
    namespace = var.var_namespace_mobius
    annotations = {
      "kubernetes.io/ingress.class"                      = "nginx"
      "nginx.ingress.kubernetes.io/use-regex"           = "true"
      "nginx.ingress.kubernetes.io/rewrite-target"      = "/contentautomation/appmanager/rest/authorization/$1"
      "nginx.ingress.kubernetes.io/proxy-read-timeout"  = "86400"
      "nginx.ingress.kubernetes.io/proxy-send-timeout"  = "86400"
      "nginx.ingress.kubernetes.io/proxy-body-size"     = "100m"
    }
  }

  spec {
    rule {
      host = var.var_ingress_hostname
      http {
        path {
          path      = "/contentautomation/rest/authorization/(.*)"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = var.var_appmanager_service_name
              port {
                number = 8521
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "studio_ingress" {
  count = var.var_deploy_nginx && var.var_deploy_studio ? 1 : 0

  depends_on = [helm_release.nginx_external, helm_release.studio]

  metadata {
    name      = "contentautomation-studio-ingress"
    namespace = var.var_namespace_mobius
    annotations = {
      "kubernetes.io/ingress.class"                         = "nginx"
      "nginx.ingress.kubernetes.io/proxy-read-timeout"     = "3600"
      "nginx.ingress.kubernetes.io/proxy-connect-timeout"  = "300"
      "nginx.ingress.kubernetes.io/proxy-body-size"        = "100m"
    }
  }

  spec {
    rule {
      host = var.var_ingress_hostname
      http {
        path {
          path      = "/contentautomation/studio/"
          path_type = "Prefix"
          backend {
            service {
              name = var.var_studio_service_name
              port {
                number = 8082
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "processengine_ingress" {
  count = var.var_deploy_nginx && var.var_deploy_processengine ? 1 : 0

  depends_on = [helm_release.nginx_external, helm_release.processengine]

  metadata {
    name      = "contentautomation-processengine-ingress"
    namespace = var.var_namespace_mobius
    annotations = {
      "kubernetes.io/ingress.class"                         = "nginx"
      "nginx.ingress.kubernetes.io/proxy-read-timeout"     = "86400"
      "nginx.ingress.kubernetes.io/proxy-send-timeout"     = "86400"
      "nginx.ingress.kubernetes.io/proxy-body-size"        = "100m"
    }
  }

  spec {
    rule {
      host = var.var_ingress_hostname
      http {
        path {
          path      = "/contentautomation/process/"
          path_type = "Prefix"
          backend {
            service {
              name = var.var_processengine_service_name
              port {
                number = 8522
              }
            }
          }
        }

        path {
          path      = "/contentautomation/mcp"
          path_type = "Prefix"
          backend {
            service {
              name = var.var_processengine_service_name
              port {
                number = 8522
              }
            }
          }
        }
      }
    }
  }
}
