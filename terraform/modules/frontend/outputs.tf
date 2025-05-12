output "service_name" {
  description = "Name of the frontend Kubernetes service"
  value       = kubernetes_service.frontend.metadata[0].name
}

output "service_port" {
  description = "Port of the frontend Kubernetes service"
  value       = kubernetes_service.frontend.spec[0].port[0].port
}

output "deployment_name" {
  description = "Name of the frontend Kubernetes deployment"
  value       = kubernetes_deployment.frontend.metadata[0].name
}

# Config maps will be added in a future update
# output "config_map_name" {
#   description = "Name of the frontend environment ConfigMap"
#   value       = kubernetes_config_map.frontend_env.metadata[0].name
# }
# 
# output "nginx_config_map_name" {
#   description = "Name of the frontend Nginx ConfigMap"
#   value       = kubernetes_config_map.nginx_config.metadata[0].name
# }
