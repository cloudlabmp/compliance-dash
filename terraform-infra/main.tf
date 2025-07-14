terraform {
  backend "local" {}
}

# Obtain one-time ECR credentials so Docker provider can push images.
data "aws_ecr_authorization_token" "auth" {}

provider "docker" {
  registry_auth {
    address  = data.aws_ecr_authorization_token.auth.proxy_endpoint
    username = data.aws_ecr_authorization_token.auth.user_name
    password = data.aws_ecr_authorization_token.auth.password
  }
}

module "ecr_docker_images" {
  source   = "./modules/ecr_docker_images"

  aws_region = var.aws_region
  services   = local.services
  tag_suffix = local.build_version
}

module "secrets" {
  source      = "./modules/secrets"
  secrets_map = local.secrets
}

output "repository_urls" {
  description = "Map of service name to ECR repository URL"
  value       = module.ecr_docker_images.repository_urls
}
