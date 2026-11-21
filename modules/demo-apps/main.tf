locals {
  # UID of the non-root "app" user in the .NET base images.
  app_uid = 1654

  apps = {
    rest-api = {
      service_name = "rest-api-service"
      service_port = 8001
      service_type = "ClusterIP"
      probe_path   = "/Demo"
      env          = {}
    }
    mvc-app = {
      service_name = "mvc-app-service"
      service_port = 8000
      service_type = var.mvc_app_service_type
      probe_path   = "/"
      env = {
        DEMO_API_HOST = "http://rest-api-service:8001"
      }
    }
  }

  labels = {
    "app.kubernetes.io/part-of"    = "demo"
    "app.kubernetes.io/managed-by" = "terraform"
  }
}

resource "kubernetes_namespace_v1" "demo" {
  metadata {
    name = var.namespace
    labels = merge(local.labels, {
      # Reject pods that don't meet the restricted Pod Security Standard.
      "pod-security.kubernetes.io/enforce"         = "restricted"
      "pod-security.kubernetes.io/enforce-version" = "latest"
    })
  }
}

resource "kubernetes_service_account_v1" "app" {
  for_each = local.apps

  metadata {
    name      = each.key
    namespace = kubernetes_namespace_v1.demo.metadata[0].name
    labels    = merge(local.labels, { "app.kubernetes.io/name" = each.key })
  }

  automount_service_account_token = false
}

resource "kubernetes_deployment_v1" "app" {
  for_each = local.apps

  metadata {
    name      = each.key
    namespace = kubernetes_namespace_v1.demo.metadata[0].name
    labels    = merge(local.labels, { "app.kubernetes.io/name" = each.key })
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        "app.kubernetes.io/name" = each.key
      }
    }

    template {
      metadata {
        labels = merge(local.labels, { "app.kubernetes.io/name" = each.key })
      }

      spec {
        service_account_name            = kubernetes_service_account_v1.app[each.key].metadata[0].name
        automount_service_account_token = false

        security_context {
          run_as_non_root = true
          run_as_user     = local.app_uid
          run_as_group    = local.app_uid
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name              = each.key
          image             = "bstraehle/${each.key}:${var.image_tag}"
          image_pull_policy = "Always"

          dynamic "env" {
            for_each = each.value.env
            content {
              name  = env.key
              value = env.value
            }
          }

          port {
            name           = "http"
            container_port = 8080
          }

          readiness_probe {
            http_get {
              path = each.value.probe_path
              port = "http"
            }
            period_seconds  = 5
            timeout_seconds = 3
          }

          liveness_probe {
            http_get {
              path = each.value.probe_path
              port = "http"
            }
            initial_delay_seconds = 10
            period_seconds        = 20
            timeout_seconds       = 3
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
          }

          # Set run_as_non_root here too: the provider sends false for an unset
          # field, which would override the pod-level setting.
          security_context {
            run_as_non_root            = true
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            capabilities {
              drop = ["ALL"]
            }
          }

          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }
        }

        volume {
          name = "tmp"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "app" {
  for_each = local.apps

  metadata {
    name      = each.value.service_name
    namespace = kubernetes_namespace_v1.demo.metadata[0].name
    labels    = merge(local.labels, { "app.kubernetes.io/name" = each.key })
  }

  spec {
    type = each.value.service_type

    selector = {
      "app.kubernetes.io/name" = each.key
    }

    port {
      name        = "http"
      port        = each.value.service_port
      target_port = "http"
    }
  }

  # Don't block apply on clusters without a load balancer controller.
  wait_for_load_balancer = each.value.service_type == "LoadBalancer"
}

resource "kubernetes_pod_disruption_budget_v1" "app" {
  for_each = local.apps

  metadata {
    name      = each.key
    namespace = kubernetes_namespace_v1.demo.metadata[0].name
    labels    = merge(local.labels, { "app.kubernetes.io/name" = each.key })
  }

  spec {
    min_available = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name" = each.key
      }
    }
  }
}
