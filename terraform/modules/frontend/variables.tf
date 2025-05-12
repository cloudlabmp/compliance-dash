variable "namespace" {
  description = "Kubernetes namespace for frontend deployment"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "image_repository" {
  description = "Docker image repository for frontend"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag for frontend"
  type        = string
  default     = "latest"
}

variable "replicas" {
  description = "Number of frontend replicas"
  type        = number
  default     = 2
}

variable "cpu_request" {
  description = "CPU request for frontend pods"
  type        = string
  default     = "50m"
}

variable "memory_request" {
  description = "Memory request for frontend pods"
  type        = string
  default     = "128Mi"
}

variable "cpu_limit" {
  description = "CPU limit for frontend pods"
  type        = string
  default     = "200m"
}

variable "memory_limit" {
  description = "Memory limit for frontend pods"
  type        = string
  default     = "256Mi"
}

variable "backend_service_name" {
  description = "Name of the backend Kubernetes service"
  type        = string
}

variable "backend_service_port" {
  description = "Port of the backend Kubernetes service"
  type        = number
  default     = 4000
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

variable "tolerations" {
  description = "List of tolerations for frontend pods"
  type = list(object({
    key      = string
    operator = string
    value    = string
    effect   = string
  }))
  default = []
}
