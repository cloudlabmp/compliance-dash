output "namespace" {
  description = "The Kubernetes namespace where resources are deployed"
  value       = kubernetes_namespace.compliance_dash.metadata[0].name
}

output "backend_service_endpoint" {
  description = "Internal endpoint for the backend service"
  value       = "${module.backend.service_name}.${kubernetes_namespace.compliance_dash.metadata[0].name}.svc.cluster.local:${module.backend.service_port}"
}

output "frontend_service_endpoint" {
  description = "Internal endpoint for the frontend service"
  value       = "${module.frontend.service_name}.${kubernetes_namespace.compliance_dash.metadata[0].name}.svc.cluster.local:${module.frontend.service_port}"
}

output "ingress_endpoint" {
  description = "Endpoint for the ingress controller"
  value       = var.enable_ingress ? (var.domain_name != "" ? "https://${var.domain_name}" : "Ingress enabled, access via load balancer") : "Ingress not enabled"
}

output "backend_secrets_arn" {
  description = "ARN of the backend secrets in AWS Secrets Manager"
  value       = module.backend.secrets_arns
  sensitive   = true
}

# VPC outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

# EKS outputs
output "cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "The endpoint for the Kubernetes API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_oidc_issuer_url" {
  description = "The URL of the OIDC Provider"
  value       = "https://${module.eks.oidc_provider_url}"
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider"
  value       = module.eks.oidc_provider_arn
}

# ECR repository outputs
output "ecr_repository_urls" {
  description = "Map of ECR repository names to their URLs"
  value       = module.ecr.repository_urls
}

# Individual repository URLs (for convenience)
output "backend_repository_url" {
  description = "URL of the backend ECR repository"
  value       = module.ecr.repository_urls["backend"]
}

output "frontend_repository_url" {
  description = "URL of the frontend ECR repository"
  value       = module.ecr.repository_urls["frontend"]
}

output "backend_image" {
  description = "Full name of the built backend image"
  value       = module.ecr.backend_image
}

output "frontend_image" {
  description = "Full name of the built frontend image"
  value       = module.ecr.frontend_image
}
