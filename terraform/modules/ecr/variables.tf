variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "AWS region for ECR repositories"
  type        = string
}

variable "repositories" {
  description = "List of ECR repositories to create"
  type = list(object({
    name            = string
    immutable       = optional(bool, true)
    scan_on_push    = optional(bool, true)
    encryption_type = optional(string, "AES256")
    kms_key_arn     = optional(string, null)
    policy          = optional(string, null)
    lifecycle_policy = optional(string, null)
  }))
  default = [
    {
      name = "backend"
      lifecycle_policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 10 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
    },
    {
      name = "frontend"
      lifecycle_policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 10 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
    }
  ]
}

variable "force_delete" {
  description = "Whether to force delete the repository even if it contains images"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "backend_dockerfile_path" {
  description = "Path to the directory containing backend Dockerfile"
  type        = string
  default     = "../backend"
}

variable "frontend_dockerfile_path" {
  description = "Path to the directory containing frontend Dockerfile"
  type        = string
  default     = "../frontend"
}

variable "api_url" {
  description = "API URL for frontend to connect to backend"
  type        = string
  default     = ""
}
