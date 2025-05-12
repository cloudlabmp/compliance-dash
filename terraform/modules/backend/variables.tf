variable "namespace" {
  description = "Kubernetes namespace for backend deployment"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "AWS region for resources"
  type        = string
}

variable "image_repository" {
  description = "Docker image repository for backend"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag for backend"
  type        = string
  default     = "latest"
}

variable "replicas" {
  description = "Number of backend replicas"
  type        = number
  default     = 2
}

variable "cpu_request" {
  description = "CPU request for backend pods"
  type        = string
  default     = "100m"
}

variable "memory_request" {
  description = "Memory request for backend pods"
  type        = string
  default     = "256Mi"
}

variable "cpu_limit" {
  description = "CPU limit for backend pods"
  type        = string
  default     = "500m"
}

variable "memory_limit" {
  description = "Memory limit for backend pods"
  type        = string
  default     = "512Mi"
}

variable "service_account_name" {
  description = "Name of the Kubernetes service account for backend with IRSA"
  type        = string
  default     = "backend-sa"
}

variable "secret_name" {
  description = "Name of the Kubernetes secret to create"
  type        = string
  default     = "backend-secrets"
}

variable "secret_names" {
  description = "List of secret names to be created in AWS Secrets Manager"
  type        = list(string)
  default     = []
}

variable "secret_values" {
  description = "List of secret values corresponding to secret_names"
  type        = list(string)
  sensitive   = true
  default     = []
}

variable "secret_env_vars" {
  description = "List of environment variable names that will reference the secrets"
  type        = list(string)
  default     = []
}

variable "enable_hpa" {
  description = "Whether to enable Horizontal Pod Autoscaler"
  type        = bool
  default     = true
}

variable "min_replicas" {
  description = "Minimum number of replicas for HPA"
  type        = number
  default     = 2
}

variable "max_replicas" {
  description = "Maximum number of replicas for HPA"
  type        = number
  default     = 10
}

variable "target_cpu_utilization_percentage" {
  description = "Target CPU utilization percentage for HPA"
  type        = number
  default     = 70
}

variable "target_memory_utilization_percentage" {
  description = "Target memory utilization percentage for HPA"
  type        = number
  default     = 80
}

variable "tolerations" {
  description = "List of tolerations for backend pods"
  type = list(object({
    key      = string
    operator = string
    value    = string
    effect   = string
  }))
  default = []
}
