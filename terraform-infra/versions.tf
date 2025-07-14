terraform {
  required_version = ">= 1.12.0"

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

# AWS provider (credentials are picked up from the environment or shared credentials file)
provider "aws" {
  region = var.aws_region
}
