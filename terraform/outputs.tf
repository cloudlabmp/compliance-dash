# ECR Outputs
output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = module.ecr_containers.repository_urls
}

output "container_image_uris" {
  description = "Container image URIs"
  value       = module.ecr_containers.image_uris
}

output "current_build_version" {
  description = "Current build version"
  value       = module.ecr_containers.build_version
}

# Networking Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

# ALB Outputs
output "frontend_url" {
  description = "Public URL of the frontend via ALB"
  value       = "http://${module.alb.alb_dns_name}"
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs.cluster_arn
}

output "frontend_service_name" {
  description = "Name of the frontend ECS service"
  value       = module.ecs.frontend_service_name
}

output "backend_service_name" {
  description = "Name of the backend ECS service"
  value       = module.ecs.backend_service_name
}

# Secrets Outputs
output "backend_openai_key_arn" {
  description = "ARN of the backend OpenAI key secret"
  value       = module.secrets_manager.backend_openai_key_arn
}

output "backend_aws_credentials_arn" {
  description = "ARN of the backend AWS credentials secret"
  value       = module.secrets_manager.backend_aws_credentials_arn
}