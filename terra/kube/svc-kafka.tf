# Deploy Kafka for Event Analytics
resource "kubernetes_service" "kafka_svc" {

  count      = var.var_deploy_eventanalytics == true ? 1 : 0
  depends_on = [
    helm_release.mobiusserver
  ]

  metadata {
    name      = "kafka"
    namespace = var.var_namespace_mobius
    labels    = merge(
      {
        "io.kompose.service" = "kafka"
      },
      var.common_labels
    )
  }

  spec {
    cluster_ip = "None"  # Headless service
    selector   = {
      "io.kompose.service" = "kafka"
    }

    port {
      name        = "9092"
      port        = 9092
      target_port = 9092
    }
  }
}

resource "kubernetes_stateful_set" "kafka" {

  count      = var.var_deploy_eventanalytics == true ? 1 : 0
  depends_on = [
    kubernetes_service.kafka_svc
  ]

  metadata {
    name      = "kafka"
    namespace = var.var_namespace_mobius
    labels    = {
      "io.kompose.service" = "kafka"
    }
  }

  spec {
    service_name = "kafka"
    replicas     = 1

    selector {
      match_labels = {
        "io.kompose.service" = "kafka"
      }
    }

    template {
      metadata {
        labels = {
          "io.kompose.service" = "kafka"
        }
      }

      spec {
        container {
          name  = "kafka"
          image = "bitnamilegacy/kafka:3.3.1-debian-11-r38"

          image_pull_policy = "IfNotPresent"

          env {
            name  = "ALLOW_PLAINTEXT_LISTENER"
            value = "yes"
          }
          env {
            name  = "KAFKA_CFG_BROKER_ID"
            value = "1"
          }
          env {
            name  = "KAFKA_CFG_CONTROLLER_LISTENER_NAMES"
            value = "CONTROLLER"
          }
          env {
            name  = "KAFKA_CFG_CONTROLLER_QUORUM_VOTERS"
            value = "1@127.0.0.1:9093"
          }
          env {
            name  = "KAFKA_CFG_LISTENERS"
            value = "PLAINTEXT://:9092,CONTROLLER://:9093"
          }
          env {
            name  = "KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP"
            value = "CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT"
          }
          env {
            name  = "KAFKA_CFG_NODE_ID"
            value = "1"
          }
          env {
            name  = "KAFKA_CFG_PROCESS_ROLES"
            value = "broker,controller"
          }
          env {
            name  = "KAFKA_ENABLE_KRAFT"
            value = "yes"
          }
          env {
            name  = "KAFKA_CFG_DELETE_TOPIC_ENABLE"
            value = "true"
          }
          env {
            name  = "KAFKA_CFG_AUTO_CREATE_TOPICS_ENABLE"
            value = "true"
          }
          env {
            name  = "KAFKA_HEAP_OPTS"
            value = "-Xmx512m -Xms128m"
          }

          port {
            container_port = 9092
          }

          resources {
            limits = {
              cpu    = "100m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
          }
        }

        restart_policy = "Always"
      }
    }
  }
}