# General configuration
region      = "us-east-1"
environment = "dev"
namespace   = "compliance-dash"
cluster_name = "compliance-dash-dev"

# VPC configuration
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
availability_zones  = ["us-east-1a", "us-east-1b"]
enable_nat_gateway  = true

# EKS configuration
kubernetes_version = "1.28"
node_instance_types = ["t3.medium"]
node_disk_size     = 20
node_desired_size  = 2
node_min_size      = 1
node_max_size      = 3

# ECR configuration
enable_ecr_module = true
backend_repository_name = "compliance-dash/backend"
frontend_repository_name = "compliance-dash/frontend"

# Backend configuration
backend_replicas = 1
backend_image_tag = "latest"

# Backend secrets
backend_secret_names = ["db-credentials", "api-keys"]
backend_secret_values = ["{\"username\":\"admin\",\"password\":\"example\"}", "{\"api_key\":\"example-key\"}"]
backend_secret_env_vars = ["DATABASE_URL", "API_KEY"]

# Frontend configuration
frontend_replicas = 1
frontend_image_tag = "latest"

# Tags
tags = {
  Project     = "ComplianceDashboard"
  ManagedBy   = "Terraform"
  Environment = "dev"
}
