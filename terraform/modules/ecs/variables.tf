variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "ID of the ECS security group"
  type        = string
}

variable "frontend_target_group_arn" {
  description = "ARN of the frontend target group"
  type        = string
}

variable "backend_target_group_arn" {
  description = "ARN of the backend target group"
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "ecs_task_frontend_role_arn" {
  description = "ARN of the ECS task role for frontend"
  type        = string
}

variable "ecs_task_backend_role_arn" {
  description = "ARN of the ECS task role for backend"
  type        = string
}

variable "container_images" {
  description = "Map of container images with URIs"
  type        = map(string)
}

variable "secret_arns" {
  description = "Map of secret ARNs"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}