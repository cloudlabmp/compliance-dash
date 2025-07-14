locals {
  # Increment to force Docker rebuild/push even if source unchanged
  build_version = 1

  # Map of services to build; paths are relative to repository root
  services = {
    frontend = {
      context    = "${path.root}/../frontend"
      dockerfile = "Dockerfile"
    }
    backend = {
      context    = "${path.root}/../backend"
      dockerfile = "Dockerfile"
    }
  }

  # Secrets to create in AWS Secrets Manager
  secrets = {
    openai_api_key = var.openai_api_key
  }
}
