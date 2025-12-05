resource "helm_release" "nginx_internal" {

  count = (
  var.var_deploy_mobiusserver == true && local.var_mobius_server_clustering_enabled == "TRUE"
  ) ? 1 : 0

  depends_on = [
    helm_release.mobiusserver
  ]

  name       = "nginx-internal-controller"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "3.34.0"
  namespace  = var.var_namespace_mobius

  values = [
    <<-EOT
controller:
  replicaCount: 1
  ingressClass: ${local.var_mobius_nginx_internal_class_name}
  service:
    type: ClusterIP
  config:
    log-format-upstream: '$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent" "$http_cookie" $upstream_addr $upstream_response_time $upstream_status'
  electionID: ingress-controller-leader
  ingressClassResource:
    name: ${local.var_mobius_nginx_internal_class_name}
    enabled: true
    default: false
    controllerValue: "k8s.io/${local.var_mobius_nginx_internal_class_name}"
EOT
  ]
}


resource "kubernetes_ingress_v1" "ingress_internal" {

  count = (
  var.var_deploy_mobiusserver == true && local.var_mobius_server_clustering_enabled == "TRUE"
  ) ? 1 : 0

  depends_on = [helm_release.nginx_internal]

  metadata {
    name        = "nginx-internal"
    namespace   = var.var_namespace_mobius
    annotations = {
      "kubernetes.io/ingress.class"                       = local.var_mobius_nginx_internal_class_name
      "nginx.ingress.kubernetes.io/affinity"              = "cookie"
      "nginx.ingress.kubernetes.io/session-cookie-name"   = "VDRLB"
      "nginx.ingress.kubernetes.io/proxy-buffer-size"     = "64k"
      "nginx.ingress.kubernetes.io/proxy-connect-timeout" = "60"
      "nginx.ingress.kubernetes.io/proxy-read-timeout"    = "60"
      "nginx.ingress.kubernetes.io/proxy-send-timeout"    = "60"
    }
  }

  spec {
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "mobius"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
}
