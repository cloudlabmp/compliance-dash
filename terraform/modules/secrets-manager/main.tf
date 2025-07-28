locals {
  secrets = {
    backend-aws-credentials = {
      description = "AWS credentials for backend service"
    }
    backend-openai-key = {
      description = "OpenAI API key for backend service"
    }
  }
}

resource "aws_secretsmanager_secret" "secrets" {
  for_each = local.secrets
  
  name        = "${var.project_name}-${var.environment}-${each.key}"
  description = each.value.description
  
  lifecycle {
    prevent_destroy = true
  }
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-${each.key}"
    Type = "secret"
  })
}

# Secret versions are managed outside of Terraform to prevent secrets from being stored in state
# The secret containers above provide the structure, but actual secret values are populated separately