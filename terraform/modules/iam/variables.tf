variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "secret_arns" {
  description = "ARNs of secrets that the backend needs access to"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}