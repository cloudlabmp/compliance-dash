locals {
  app_name = "compliance-dash-backend"
  labels = {
    app         = local.app_name
    environment = var.environment
  }
}

# Create AWS Secrets Manager secrets
resource "aws_secretsmanager_secret" "backend_secrets" {
  count = length(var.secret_names)
  
  name                    = "${var.environment}-compliance-dash-${var.secret_names[count.index]}"
  recovery_window_in_days = 0  # No recovery window for easier testing
  
  tags = {
    Environment = var.environment
    Application = "compliance-dashboard"
  }
}

# Create secret versions with actual values using write-only arguments
resource "aws_secretsmanager_secret_version" "backend_secret_versions" {
  count = length(var.secret_names)
  
  secret_id = aws_secretsmanager_secret.backend_secrets[count.index].id
  
  # Use secret_string_wo write-only argument to prevent secret values from being stored in state
  secret_string_wo = var.secret_values[count.index]
  secret_string_wo_version = 1
}

# Create IAM policy document for backend service account to access secrets
data "aws_iam_policy_document" "backend_secrets_access" {
  statement {
    sid    = "AllowBackendToGetSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = aws_secretsmanager_secret.backend_secrets[*].arn
  }
}

# Create Kubernetes deployment for backend
resource "kubernetes_deployment" "backend" {
  metadata {
    name      = "${var.environment}-backend"
    namespace = var.namespace
    labels = {
      app         = "backend"
      environment = var.environment
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app         = "backend"
        environment = var.environment
      }
    }

    template {
      metadata {
        labels = {
          app         = "backend"
          environment = var.environment
        }
      }

      spec {
        # Use the service account with IRSA
        service_account_name = var.service_account_name

        # Node affinity for backend pods
        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "kubernetes.io/arch"
                  operator = "In"
                  values   = ["amd64"]
                }
              }
            }
          }
        }

        # Add tolerations if specified
        dynamic "toleration" {
          for_each = var.tolerations
          content {
            key      = toleration.value.key
            operator = toleration.value.operator
            value    = toleration.value.value
            effect   = toleration.value.effect
          }
        }

        container {
          name  = "backend"
          image = "${var.image_repository}:${var.image_tag}"

          port {
            container_port = 4000
          }

          # Resource limits
          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }

          # Environment variables for AWS SDK to use IRSA
          env {
            name  = "AWS_SDK_LOAD_CONFIG"
            value = "true"
          }
          
          env {
            name  = "AWS_REGION"
            value = var.region
          }
          
          # Environment variables with secret references
          dynamic "env" {
            for_each = var.secret_env_vars
            content {
              name  = env.value
              value = "aws-sm://${var.environment}-compliance-dash-${var.secret_names[index(var.secret_env_vars, env.value)]}"
            }
          }

          # Add environment variables for configuration
          env {
            name  = "NODE_ENV"
            value = var.environment
          }

          env {
            name  = "PORT"
            value = "4000"
          }

          # Liveness probe
          liveness_probe {
            http_get {
              path = "/health"
              port = 4000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          # Readiness probe
          readiness_probe {
            http_get {
              path = "/health"
              port = 4000
            }
            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }
      }
    }
  }
}

# Create Kubernetes service for backend
resource "kubernetes_service" "backend" {
  metadata {
    name      = local.app_name
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    selector = local.labels
    
    port {
      port        = 4000
      target_port = "http"
      protocol    = "TCP"
      name        = "http"
    }

    type = "ClusterIP"
  }
}

# Create horizontal pod autoscaler for backend
resource "kubernetes_horizontal_pod_autoscaler_v2" "backend_hpa" {
  count = var.enable_hpa ? 1 : 0

  metadata {
    name      = "${local.app_name}-hpa"
    namespace = var.namespace
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.backend.metadata[0].name
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.target_cpu_utilization_percentage
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = var.target_memory_utilization_percentage
        }
      }
    }
  }
}
