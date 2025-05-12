variable "namespace" {
  description = "Kubernetes namespace to install the CSI driver"
  type        = string
}

variable "chart_version" {
  description = "Helm chart version for secrets-store-csi-driver"
  type        = string
  default     = "1.3.4"
}

variable "aws_provider_version" {
  description = "Helm chart version for AWS Secrets Manager provider"
  type        = string
  default     = "0.3.4"
}
