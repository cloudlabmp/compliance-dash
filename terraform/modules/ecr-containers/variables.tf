variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "build_version" {
  description = "Build version tag for images"
  type        = string
}

variable "ecr_registry" {
  description = "ECR registry endpoint"
  type        = string
}

variable "containers" {
  description = "Map of containers to build and push"
  type = map(object({
    context_path = string
    dockerfile   = string
    platform     = string
  }))
}

variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}