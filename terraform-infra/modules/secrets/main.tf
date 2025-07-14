##############################
# Secrets Module (Compliance Dash)
# Creates Secrets Manager secrets and versions using write-only values, plus
# an IAM policy for read access which should be attached to the backend task
# execution role.
##############################

# 1. Secret metadata
resource "aws_secretsmanager_secret" "this" {
  for_each    = var.secrets_map
  name        = each.key
  description = "Managed by Terraform for Compliance-Dash backend"
  recovery_window_in_days = 0
  tags = {
    App = "compliance-dash"
  }
}

# 2. Secret value (WRITE-ONLY)
resource "aws_secretsmanager_secret_version" "this" {
  for_each         = var.secrets_map
  secret_id        = aws_secretsmanager_secret.this[each.key].id
  secret_string_wo = each.value  # write-only attribute; never stored in state
  secret_string_wo_version = 1
  version_stages   = ["AWSCURRENT"]
}

# 3. IAM policy document granting read-only access to created secrets (+ AWS Config)
data "aws_iam_policy_document" "read" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "config:DescribeConfigRules",
      "config:GetComplianceDetailsByConfigRule"
    ]
    resources = [for s in aws_secretsmanager_secret.this : s.arn]
  }
}

resource "aws_iam_policy" "read_secrets" {
  name   = "compliance-dash-backend-read-secrets"
  policy = data.aws_iam_policy_document.read.json
}
