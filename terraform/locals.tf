locals {
  # Increment this value to force container rebuilds
  build_tag = "v1.0.1"
  
  # Build version combines build tag with timestamp for uniqueness
  build_version = "${local.build_tag}-${formatdate("YYYYMMDD-HHMM", timestamp())}"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    BuildTag    = local.build_tag
  }
}