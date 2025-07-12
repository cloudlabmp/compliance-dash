variable "namespace" {
  description = "Kubernetes namespace for the ingress resources"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "frontend_service_name" {
  description = "Name of the frontend service"
  type        = string
  default     = "frontend"
}

variable "frontend_service_port" {
  description = "Port of the frontend service"
  type        = number
  default     = 80
}

variable "backend_service_name" {
  description = "Name of the backend service"
  type        = string
  default     = "backend"
}

variable "backend_service_port" {
  description = "Port of the backend service"
  type        = number
  default     = 8080
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the OIDC provider for the EKS cluster (without https://)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster is deployed"
  type        = string
}
