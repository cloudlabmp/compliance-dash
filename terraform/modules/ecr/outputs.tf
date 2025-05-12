output "repository_urls" {
  description = "Map of repository names to their URLs"
  value = {
    for name, repo in aws_ecr_repository.repositories : name => repo.repository_url
  }
}

output "repository_arns" {
  description = "Map of repository names to their ARNs"
  value = {
    for name, repo in aws_ecr_repository.repositories : name => repo.arn
  }
}

output "backend_image" {
  description = "Full image name of the built backend image"
  value = contains([for repo in var.repositories : repo.name], "backend") ? docker_registry_image.backend[0].name : null
}

output "frontend_image" {
  description = "Full image name of the built frontend image"
  value = contains([for repo in var.repositories : repo.name], "frontend") ? docker_registry_image.frontend[0].name : null
}

output "backend_image_tag" {
  description = "Tag of the built backend image"
  value = contains([for repo in var.repositories : repo.name], "backend") ? split(":", docker_registry_image.backend[0].name)[1] : null
}

output "frontend_image_tag" {
  description = "Tag of the built frontend image"
  value = contains([for repo in var.repositories : repo.name], "frontend") ? split(":", docker_registry_image.frontend[0].name)[1] : null
}
