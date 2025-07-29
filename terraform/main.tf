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

# Networking Module
module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  environment  = var.environment

  tags = local.common_tags
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
  
  secret_arns = [
    module.secrets_manager.backend_aws_credentials_arn,
    module.secrets_manager.backend_openai_key_arn
  ]

  tags = local.common_tags
}

# ALB Module
module "alb" {
  source = "./modules/alb"

  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = module.networking.vpc_id
  public_subnet_ids       = module.networking.public_subnet_ids
  alb_security_group_id   = module.networking.alb_security_group_id

  tags = local.common_tags
}

# ECS Module
module "ecs" {
  source = "./modules/ecs"

  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = module.networking.vpc_id
  private_subnet_ids      = module.networking.private_subnet_ids
  ecs_security_group_id   = module.networking.ecs_security_group_id

  frontend_target_group_arn     = module.alb.frontend_target_group_arn
  backend_target_group_arn      = module.alb.backend_target_group_arn

  ecs_task_execution_role_arn   = module.iam.ecs_task_execution_role_arn
  ecs_task_frontend_role_arn    = module.iam.ecs_task_frontend_role_arn
  ecs_task_backend_role_arn     = module.iam.ecs_task_backend_role_arn

  container_images = module.ecr_containers.image_uris

  secret_arns = {
    backend-aws-credentials = module.secrets_manager.backend_aws_credentials_arn
    backend-openai-key      = module.secrets_manager.backend_openai_key_arn
  }

  tags = local.common_tags

  depends_on = [
    module.ecr_containers,
    module.secrets_manager,
    module.networking,
    module.iam,
    module.alb
  ]
}