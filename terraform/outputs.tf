output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = module.ecr_containers.repository_urls
}

output "container_image_uris" {
  description = "Container image URIs"
  value       = module.ecr_containers.image_uris
}

output "current_build_version" {
  description = "Current build version"
  value       = module.ecr_containers.build_version
}