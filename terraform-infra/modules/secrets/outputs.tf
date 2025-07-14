output "secret_arns" {
  description = "List of ARNs for all created Secrets Manager secrets"
  value       = [for s in aws_secretsmanager_secret.this : s.arn]
}

output "read_secrets_policy_arn" {
  description = "ARN of IAM policy that grants read-only access to the secrets and AWS Config APIs"
  value       = aws_iam_policy.read_secrets.arn
}
