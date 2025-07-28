output "repository_urls" {
  description = "URLs of the ECR repositories"
  value = {
    for k, v in aws_ecr_repository.repositories : k => v.repository_url
  }
}

output "image_uris" {
  description = "Full URIs of the pushed images"
  value = {
    for k, v in docker_registry_image.pushed_images : k => v.name
  }
}

output "build_version" {
  description = "Current build version"
  value       = var.build_version
}