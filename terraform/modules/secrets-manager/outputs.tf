output "secret_arns" {
  description = "ARNs of the created secrets"
  value = {
    for k, v in aws_secretsmanager_secret.secrets : k => v.arn
  }
}

output "secret_names" {
  description = "Names of the created secrets"
  value = {
    for k, v in aws_secretsmanager_secret.secrets : k => v.name
  }
}

output "backend_aws_credentials_arn" {
  description = "ARN of the backend AWS credentials secret"
  value       = aws_secretsmanager_secret.secrets["backend-aws-credentials"].arn
}

output "backend_openai_key_arn" {
  description = "ARN of the backend OpenAI key secret"
  value       = aws_secretsmanager_secret.secrets["backend-openai-key"].arn
}