output "ingress_name" {
  description = "Name of the created ingress resource"
  value       = kubernetes_ingress_v1.compliance_dash_ingress.metadata[0].name
}

output "ingress_namespace" {
  description = "Namespace of the created ingress resource"
  value       = kubernetes_ingress_v1.compliance_dash_ingress.metadata[0].namespace
}

output "ingress_hosts" {
  description = "Hosts configured in the ingress resource"
  value       = kubernetes_ingress_v1.compliance_dash_ingress.spec[0].rule[*].host
}
