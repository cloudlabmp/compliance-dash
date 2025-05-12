output "service_account_annotations" {
  description = "Map of service account names to their annotations"
  value       = { for name, annotation in kubernetes_annotations.service_account_annotations : name => annotation.annotations }
}

output "service_account_roles" {
  description = "Map of service account names to their IAM role ARNs"
  value       = { for name, role in aws_iam_role.service_account_role : name => role.arn }
}

output "service_account_policies" {
  description = "Map of service account names to their IAM policy ARNs"
  value       = { for name, policy in aws_iam_policy.service_account_policy : name => policy.arn }
}
