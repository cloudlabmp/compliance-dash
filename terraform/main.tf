terraform {
  required_version = ">= 1.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ecr_authorization_token" "token" {}

provider "docker" {
  registry_auth {
    address  = data.aws_ecr_authorization_token.token.proxy_endpoint
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
  }
}

module "secrets_manager" {
  source = "./modules/secrets-manager"
  
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  
  tags = local.common_tags
}

module "ecr_containers" {
  source = "./modules/ecr-containers"

  project_name    = var.project_name
  environment     = var.environment
  build_version   = local.build_version
  ecr_registry    = data.aws_ecr_authorization_token.token.proxy_endpoint

  containers = {
    frontend = {
      context_path = "../frontend"
      dockerfile   = "Dockerfile"
      platform     = "linux/amd64"
    }
    backend = {
      context_path = "../backend"
      dockerfile   = "Dockerfile"
      platform     = "linux/amd64"
    }
  }

  tags = local.common_tags
}