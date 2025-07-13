terraform {
  required_version = ">= 1.12.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.0"
    }
  }
  
  # Uncomment to configure backend
  # backend "s3" {
  #   bucket         = "compliance-dash-terraform-state"
  #   key            = "terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "compliance-dash-terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

# Configure kubernetes provider to use EKS module outputs
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_id]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_id]
    }
  }
}

# Create VPC for EKS cluster
module "vpc" {
  source      = "./modules/vpc"
  environment = var.environment
  vpc_name    = "${var.environment}-compliance-dash-vpc"
  vpc_cidr    = var.vpc_cidr
  cluster_name = var.cluster_name
  
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  enable_nat_gateway   = var.enable_nat_gateway
  
  tags = var.tags
}

# Create EKS cluster
module "eks" {
  source      = "./modules/eks"
  environment = var.environment
  cluster_name = var.cluster_name
  kubernetes_version = var.kubernetes_version
  
  # Network configuration
  subnet_ids = concat(module.vpc.private_subnet_ids, module.vpc.public_subnet_ids)
  security_group_ids = [module.vpc.eks_cluster_security_group_id]
  
  # Node group configuration
  node_instance_types = var.node_instance_types
  node_disk_size      = var.node_disk_size
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  
  tags = var.tags
  
  depends_on = [module.vpc]
}

# Create namespace for compliance dashboard
resource "kubernetes_namespace" "compliance_dash" {
  metadata {
    name = var.namespace
    labels = {
      name        = var.namespace
      environment = var.environment
    }
  }
  
  depends_on = [module.eks]
}

# Create the backend service account first without IRSA
resource "kubernetes_service_account" "backend_sa" {
  metadata {
    name      = "backend-sa"
    namespace = kubernetes_namespace.compliance_dash.metadata[0].name
    labels = {
      "app.kubernetes.io/name"       = "backend"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "compliance-dashboard"
      "environment"                  = var.environment
    }
  }
  
  automount_service_account_token = true
  
  depends_on = [kubernetes_namespace.compliance_dash]
}

# Deploy ECR repositories and build/push Docker images
module "ecr" {
  source      = "./modules/ecr"
  environment = var.environment
  region      = var.region
  
  # Docker build paths
  backend_dockerfile_path  = var.backend_dockerfile_path
  frontend_dockerfile_path = var.frontend_dockerfile_path
  
  # API URL for frontend configuration
  api_url = var.api_url
  
  # Repository configuration
  repositories = var.ecr_repositories
  force_delete = var.force_delete_repositories
  
  tags = var.tags
}

# Deploy backend application
module "backend" {
  source      = "./modules/backend"
  namespace   = kubernetes_namespace.compliance_dash.metadata[0].name
  environment = var.environment
  region      = var.region
  
  # Application configuration from ECR
  image_repository = split(":", module.ecr.backend_image)[0]
  image_tag        = module.ecr.backend_image_tag
  replicas         = var.backend_replicas
  
  # Resource limits
  cpu_request    = var.backend_cpu_request
  memory_request = var.backend_memory_request
  cpu_limit      = var.backend_cpu_limit
  memory_limit   = var.backend_memory_limit
  
  # Service account for IRSA
  service_account_name = kubernetes_service_account.backend_sa.metadata[0].name
  
  # Environment variables and secrets
  secret_names = var.backend_secret_names
  secret_values = var.backend_secret_values
  secret_env_vars = var.backend_secret_env_vars
  
  depends_on = [kubernetes_service_account.backend_sa, module.ecr]
}

# Deploy frontend application
module "frontend" {
  source      = "./modules/frontend"
  namespace   = kubernetes_namespace.compliance_dash.metadata[0].name
  environment = var.environment
  
  # Application configuration from ECR
  image_repository = split(":", module.ecr.frontend_image)[0]
  image_tag        = module.ecr.frontend_image_tag
  replicas         = var.frontend_replicas
  
  # Resource limits
  cpu_request    = var.frontend_cpu_request
  memory_request = var.frontend_memory_request
  cpu_limit      = var.frontend_cpu_limit
  memory_limit   = var.frontend_memory_limit
  
  # Backend service information for frontend configuration
  backend_service_name = module.backend.service_name
  backend_service_port = module.backend.service_port
  
  depends_on = [module.backend, module.ecr]
}

# Deploy IRSA for AWS IAM integration with Kubernetes service accounts
module "irsa" {
  source         = "./modules/irsa"
  cluster_name   = module.eks.cluster_id
  namespace      = kubernetes_namespace.compliance_dash.metadata[0].name
  environment    = var.environment
  application_name = "compliance-dashboard"
  
  # Service accounts with their IAM policies
  service_accounts = [
    {
      name = "backend-sa"
      policy_document = module.backend.policy_document
    }
  ]
  
  depends_on = [module.backend]
}

# Deploy ingress controller if enabled
module "ingress" {
  count       = var.enable_ingress ? 1 : 0
  source      = "./modules/ingress"
  namespace   = kubernetes_namespace.compliance_dash.metadata[0].name
  environment = var.environment
  
  # Service information
  frontend_service_name = module.frontend.service_name
  frontend_service_port = module.frontend.service_port
  backend_service_name  = module.backend.service_name
  backend_service_port  = module.backend.service_port
  
  # AWS Load Balancer Controller configuration
  cluster_name       = module.eks.cluster_id
  oidc_provider_arn  = module.eks.oidc_provider_arn
  oidc_provider_url  = module.eks.oidc_provider_url
  aws_region         = var.region
  vpc_id             = module.vpc.vpc_id
  
  depends_on = [module.frontend, module.backend, module.eks, module.vpc]
}