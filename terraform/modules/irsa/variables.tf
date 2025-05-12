variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace where service accounts will be created"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "application_name" {
  description = "Name of the application these service accounts belong to"
  type        = string
  default     = "compliance-dashboard"
}

variable "service_accounts" {
  description = "List of service accounts to create with their IAM policies"
  type = list(object({
    name            = string
    policy_document = string
  }))
}
