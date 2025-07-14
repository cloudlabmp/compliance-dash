terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

locals {
  tag = var.tag_suffix
}

resource "aws_ecr_repository" "this" {
  for_each = var.services
  name     = each.key
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    ManagedBy = "Terraform"
  }
}

data "aws_ecr_authorization_token" "auth" {}

resource "docker_image" "this" {
  for_each = var.services
  name = "${aws_ecr_repository.this[each.key].repository_url}:${local.tag}"
  build {
    context    = each.value.context
    dockerfile = each.value.dockerfile
  }
}

resource "docker_registry_image" "push" {
  for_each = var.services
  name          = docker_image.this[each.key].name
  keep_remotely = true
}

output "repository_urls" {
  value = { for k, repo in aws_ecr_repository.this : k => repo.repository_url }
}
