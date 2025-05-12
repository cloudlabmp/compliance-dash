# Ingress module for compliance dashboard
# This is a placeholder module that will be implemented later

resource "kubernetes_ingress_v1" "compliance_dash_ingress" {
  metadata {
    name      = "compliance-dash-ingress"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "compliance-dashboard"
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = var.environment
    }
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
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
              name = var.frontend_service_name
              port {
                number = var.frontend_service_port
              }
            }
          }
        }
        
        path {
          path      = "/api"
          path_type = "Prefix"
          backend {
            service {
              name = var.backend_service_name
              port {
                number = var.backend_service_port
              }
            }
          }
        }
      }
    }
  }
}
