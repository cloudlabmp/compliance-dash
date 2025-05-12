output "service_name" {
  description = "Name of the backend Kubernetes service"
  value       = kubernetes_service.backend.metadata[0].name
}

output "service_port" {
  description = "Port of the backend Kubernetes service"
  value       = kubernetes_service.backend.spec[0].port[0].port
}

output "deployment_name" {
  description = "Name of the backend Kubernetes deployment"
  value       = kubernetes_deployment.backend.metadata[0].name
}

output "secrets_arns" {
  description = "ARN of the backend secrets in AWS Secrets Manager"
  value       = { for key, secret in aws_secretsmanager_secret.backend_secrets : key => secret.arn }
  sensitive   = true
}

output "policy_document" {
  description = "IAM policy document for backend service account to access secrets"
  value       = data.aws_iam_policy_document.backend_secrets_access.json
}
