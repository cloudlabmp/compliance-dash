output "ingress_name" {
  description = "Name of the created ingress resource"
  value       = kubernetes_ingress_v1.compliance_dash_ingress.metadata[0].name
}

output "ingress_namespace" {
  description = "Namespace of the created ingress resource"
  value       = kubernetes_ingress_v1.compliance_dash_ingress.metadata[0].namespace
}

output "ingress_hostname" {
  description = "Hostname of the ALB created by the ingress"
  value       = length(kubernetes_ingress_v1.compliance_dash_ingress.status) > 0 && length(kubernetes_ingress_v1.compliance_dash_ingress.status[0].load_balancer) > 0 && length(kubernetes_ingress_v1.compliance_dash_ingress.status[0].load_balancer[0].ingress) > 0 ? kubernetes_ingress_v1.compliance_dash_ingress.status[0].load_balancer[0].ingress[0].hostname : "ALB not yet created - run terraform apply again after a few minutes"
}

output "ingress_hosts" {
  description = "Hosts configured in the ingress resource"
  value       = kubernetes_ingress_v1.compliance_dash_ingress.spec[0].rule[*].host
}

output "load_balancer_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM role"
  value       = aws_iam_role.aws_load_balancer_controller.arn
}
