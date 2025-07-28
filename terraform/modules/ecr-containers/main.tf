# ECR Repositories
resource "aws_ecr_repository" "repositories" {
  for_each = var.containers

  name                 = "${var.project_name}-${each.key}"
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${each.key}"
  })
}

# ECR Lifecycle Policies
resource "aws_ecr_lifecycle_policy" "lifecycle_policies" {
  for_each = aws_ecr_repository.repositories

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Docker Images Build
resource "docker_image" "images" {
  for_each = var.containers

  name = "${replace(var.ecr_registry, "https://", "")}/${aws_ecr_repository.repositories[each.key].name}:${var.build_version}"

  build {
    context    = each.value.context_path
    dockerfile = each.value.dockerfile
    platform   = each.value.platform
    
    # Force rebuild when build_version changes
    build_args = {
      BUILD_VERSION = var.build_version
    }
  }

  # Ensure repository exists before building
  depends_on = [aws_ecr_repository.repositories]
}

# Push Images to ECR
resource "docker_registry_image" "pushed_images" {
  for_each = docker_image.images

  name = each.value.name

  # Ensure image is built before pushing
  depends_on = [docker_image.images]
}