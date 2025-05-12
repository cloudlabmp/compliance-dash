terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

locals {
  repositories = {
    for repo in var.repositories : repo.name => repo
  }
  
  # Construct image tags with timestamp for immutability
  image_tags = {
    for name, repo in local.repositories : name => "${var.environment}-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  }
}

# Create ECR repositories
resource "aws_ecr_repository" "repositories" {
  for_each = local.repositories

  name                 = each.key
  image_tag_mutability = each.value.immutable ? "IMMUTABLE" : "MUTABLE"
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = each.value.scan_on_push
  }

  encryption_configuration {
    encryption_type = each.value.encryption_type
    kms_key         = each.value.kms_key_arn
  }

  tags = merge(
    var.tags,
    {
      Name        = each.key
      Environment = var.environment
    }
  )
}

# Set repository policies
resource "aws_ecr_repository_policy" "policies" {
  for_each = { for name, repo in local.repositories : name => repo if repo.policy != null }

  repository = aws_ecr_repository.repositories[each.key].name
  policy     = each.value.policy
}

# Configure lifecycle policies
resource "aws_ecr_lifecycle_policy" "lifecycle_policies" {
  for_each = { for name, repo in local.repositories : name => repo if repo.lifecycle_policy != null }

  repository = aws_ecr_repository.repositories[each.key].name
  policy     = each.value.lifecycle_policy
}

# Docker provider configuration
provider "docker" {
  registry_auth {
    address  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
    username = "AWS"
    password = data.aws_ecr_authorization_token.token.password
  }
}

# Get AWS account ID for ECR URL
data "aws_caller_identity" "current" {}

# Get ECR authorization token for Docker provider
data "aws_ecr_authorization_token" "token" {}

# Build and push backend image
resource "docker_image" "backend" {
  count = contains([for repo in var.repositories : repo.name], "backend") ? 1 : 0
  
  name = "${aws_ecr_repository.repositories["backend"].repository_url}:${local.image_tags["backend"]}"
  
  build {
    context    = var.backend_dockerfile_path
    dockerfile = "Dockerfile"
    target     = "prod"
    
    # Pass build args if needed
    build_args = {
      NODE_ENV = var.environment
    }
    
    # Add labels
    labels = {
      environment = var.environment
      version     = local.image_tags["backend"]
      managed_by  = "terraform"
    }
  }

  # Push the image to ECR
  triggers = {
    # Rebuild when Dockerfile or package.json changes
    dockerfile_hash = filesha256("${var.backend_dockerfile_path}/Dockerfile")
    package_hash    = filesha256("${var.backend_dockerfile_path}/package.json")
  }

  # Ensure repository exists before pushing
  depends_on = [aws_ecr_repository.repositories]
}

# Build and push frontend image
resource "docker_image" "frontend" {
  count = contains([for repo in var.repositories : repo.name], "frontend") ? 1 : 0
  
  name = "${aws_ecr_repository.repositories["frontend"].repository_url}:${local.image_tags["frontend"]}"
  
  build {
    context    = var.frontend_dockerfile_path
    dockerfile = "Dockerfile"
    
    # Pass build args if needed
    build_args = {
      REACT_APP_API_URL = var.api_url
      REACT_APP_ENV     = var.environment
    }
    
    # Add labels
    labels = {
      environment = var.environment
      version     = local.image_tags["frontend"]
      managed_by  = "terraform"
    }
  }

  # Push the image to ECR
  triggers = {
    # Rebuild when Dockerfile or package.json changes
    dockerfile_hash = filesha256("${var.frontend_dockerfile_path}/Dockerfile")
    package_hash    = filesha256("${var.frontend_dockerfile_path}/package.json")
  }

  # Ensure repository exists before pushing
  depends_on = [aws_ecr_repository.repositories]
}

# Push backend image to ECR
resource "docker_registry_image" "backend" {
  count = contains([for repo in var.repositories : repo.name], "backend") ? 1 : 0
  
  name          = docker_image.backend[0].name
  keep_remotely = true

  depends_on = [docker_image.backend]
}

# Push frontend image to ECR
resource "docker_registry_image" "frontend" {
  count = contains([for repo in var.repositories : repo.name], "frontend") ? 1 : 0
  
  name          = docker_image.frontend[0].name
  keep_remotely = true

  depends_on = [docker_image.frontend]
}
