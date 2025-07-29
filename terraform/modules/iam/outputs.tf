output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_backend_role_arn" {
  description = "ARN of the ECS task role for backend"
  value       = aws_iam_role.ecs_task_backend.arn
}

output "ecs_task_frontend_role_arn" {
  description = "ARN of the ECS task role for frontend"
  value       = aws_iam_role.ecs_task_frontend.arn
}

output "secrets_access_policy_arn" {
  description = "ARN of the secrets access policy"
  value       = aws_iam_policy.secrets_access.arn
}