variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "compliance-dash"
}

variable "namespace" {
  description = "Kubernetes namespace for compliance dashboard"
  type        = string
  default     = "compliance-dash"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Docker build paths
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

# ECR configuration
variable "ecr_repositories" {
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

variable "force_delete_repositories" {
  description = "Whether to force delete ECR repositories even if they contain images"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# VPC Variables
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  description = "Availability zones to use for the subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "enable_nat_gateway" {
  description = "Whether to enable NAT gateway for private subnets"
  type        = bool
  default     = true
}

# EKS Variables
variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "node_instance_types" {
  description = "List of instance types for the EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 20
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

# Backend image configuration (used as fallback if ECR module is disabled)
variable "backend_image_repository" {
  description = "Docker image repository for backend (fallback if ECR module is disabled)"
  type        = string
  default     = "compliance-dash-backend"
}

variable "backend_image_tag" {
  description = "Docker image tag for backend (fallback if ECR module is disabled)"
  type        = string
  default     = "latest"
}

# Frontend image configuration (used as fallback if ECR module is disabled)
variable "frontend_image_repository" {
  description = "Docker image repository for frontend (fallback if ECR module is disabled)"
  type        = string
  default     = "compliance-dash-frontend"
}

variable "frontend_image_tag" {
  description = "Docker image tag for frontend (fallback if ECR module is disabled)"
  type        = string
  default     = "latest"
}

variable "backend_replicas" {
  description = "Number of backend replicas"
  type        = number
  default     = 2
}

variable "backend_cpu_request" {
  description = "CPU request for backend pods"
  type        = string
  default     = "100m"
}

variable "backend_memory_request" {
  description = "Memory request for backend pods"
  type        = string
  default     = "256Mi"
}

variable "backend_cpu_limit" {
  description = "CPU limit for backend pods"
  type        = string
  default     = "500m"
}

variable "backend_memory_limit" {
  description = "Memory limit for backend pods"
  type        = string
  default     = "512Mi"
}

variable "backend_secret_names" {
  description = "List of backend secret names to be created in AWS Secrets Manager"
  type        = list(string)
  default     = ["db-credentials", "api-keys"]
}

variable "backend_secret_values" {
  description = "List of backend secret values corresponding to secret_names"
  type        = list(string)
  sensitive   = true
  default     = []
}

variable "backend_secret_env_vars" {
  description = "List of environment variable names that will reference the secrets"
  type        = list(string)
  default     = ["DATABASE_URL", "API_KEY"]
}

# Backend secrets are now defined using backend_secret_names, backend_secret_values, and backend_secret_env_vars

# Frontend configuration
variable "frontend_replicas" {
  description = "Number of frontend replicas"
  type        = number
  default     = 2
}

variable "frontend_cpu_request" {
  description = "CPU request for frontend pods"
  type        = string
  default     = "50m"
}

variable "frontend_memory_request" {
  description = "Memory request for frontend pods"
  type        = string
  default     = "128Mi"
}

variable "frontend_cpu_limit" {
  description = "CPU limit for frontend pods"
  type        = string
  default     = "200m"
}

variable "frontend_memory_limit" {
  description = "Memory limit for frontend pods"
  type        = string
  default     = "256Mi"
}

# ECR module configuration
variable "enable_ecr_module" {
  description = "Whether to enable the ECR module"
  type        = bool
  default     = true
}

variable "backend_repository_name" {
  description = "Name of the backend ECR repository"
  type        = string
  default     = "compliance-dash/backend"
}

variable "frontend_repository_name" {
  description = "Name of the frontend ECR repository"
  type        = string
  default     = "compliance-dash/frontend"
}

# Ingress configuration
variable "enable_ingress" {
  description = "Whether to enable ingress controller"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS"
  type        = string
  default     = ""
}
