locals {
  app_name = "compliance-dash-frontend"
  labels = {
    app         = local.app_name
    environment = var.environment
  }
}

# Create ConfigMap for frontend environment variables
resource "kubernetes_config_map" "frontend_config" {
  metadata {
    name      = "${local.app_name}-config"
    namespace = var.namespace
    labels    = local.labels
  }

  data = {
    # Frontend runtime configuration
    "REACT_APP_API_URL"      = "http://${var.backend_service_name}:${var.backend_service_port}"
    "REACT_APP_ENVIRONMENT"  = var.environment
    "REACT_APP_VERSION"      = var.image_tag
    "REACT_APP_BUILD_DATE"   = timestamp()
  }
}

# Create Kubernetes deployment for frontend
resource "kubernetes_deployment" "frontend" {
  metadata {
    name      = local.app_name
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = local.labels
    }

    template {
      metadata {
        labels = local.labels
        annotations = {
          # Force redeployment when config changes
          "config-checksum" = sha256(jsonencode(kubernetes_config_map.frontend_config.data))
        }
      }

      spec {
        container {
          name  = local.app_name
          image = "${var.image_repository}:${var.image_tag}"
          
          port {
            container_port = 3000
            name           = "http"
          }
          
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
          
          # Mount environment variables from ConfigMap
          env_from {
            config_map_ref {
              name = kubernetes_config_map.frontend_config.metadata[0].name
            }
          }
          
          # Add custom nginx configuration through volume mount
          volume_mount {
            name       = "nginx-config"
            mount_path = "/etc/nginx/conf.d"
            read_only  = true
          }
          
          liveness_probe {
            http_get {
              path = "/"
              port = "http"
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
          
          readiness_probe {
            http_get {
              path = "/"
              port = "http"
            }
            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }
        
        # Volume for nginx configuration
        volume {
          name = "nginx-config"
          config_map {
            name = kubernetes_config_map.frontend_nginx_config.metadata[0].name
            items {
              key  = "default.conf"
              path = "default.conf"
            }
          }
        }
        
        # Use node affinity for better pod placement
        affinity {
          node_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 1
              preference {
                match_expressions {
                  key      = "node-type"
                  operator = "In"
                  values   = ["frontend"]
                }
              }
            }
          }
          # Anti-affinity to spread replicas across nodes
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 100
              pod_affinity_term {
                label_selector {
                  match_expressions {
                    key      = "app"
                    operator = "In"
                    values   = [local.app_name]
                  }
                }
                topology_key = "kubernetes.io/hostname"
              }
            }
          }
        }
        
        # Add tolerations if needed
        dynamic "toleration" {
          for_each = var.tolerations
          content {
            key      = toleration.value.key
            operator = toleration.value.operator
            value    = toleration.value.value
            effect   = toleration.value.effect
          }
        }
      }
    }
  }
}

# Create ConfigMap for Nginx configuration
resource "kubernetes_config_map" "frontend_nginx_config" {
  metadata {
    name      = "${local.app_name}-nginx-config"
    namespace = var.namespace
    labels    = local.labels
  }

  data = {
    "default.conf" = <<-EOT
      server {
        listen 3000;
        server_name _;
        
        root /usr/share/nginx/html;
        index index.html;
        
        # API proxy configuration
        location /api/ {
          proxy_pass http://${var.backend_service_name}:${var.backend_service_port}/;
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection 'upgrade';
          proxy_set_header Host $host;
          proxy_cache_bypass $http_upgrade;
        }
        
        # For React Router, always serve index.html for any non-file URLs
        location / {
          try_files $uri $uri/ /index.html;
        }
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
          expires 30d;
          add_header Cache-Control "public, no-transform";
        }
        
        # Security headers
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
      }
    EOT
  }
}

# Create Kubernetes service for frontend
resource "kubernetes_service" "frontend" {
  metadata {
    name      = local.app_name
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    selector = local.labels
    
    port {
      port        = 3000
      target_port = "http"
      protocol    = "TCP"
      name        = "http"
    }

    type = "ClusterIP"
  }
}

# Create horizontal pod autoscaler for frontend
resource "kubernetes_horizontal_pod_autoscaler_v2" "frontend_hpa" {
  count = var.enable_hpa ? 1 : 0

  metadata {
    name      = "${local.app_name}-hpa"
    namespace = var.namespace
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.frontend.metadata[0].name
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
  }
}
