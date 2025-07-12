locals {
  # Create a map of service account names to their configurations
  service_accounts = {
    for sa in var.service_accounts : sa.name => sa
  }
}

# Create IAM policy for each service account
resource "aws_iam_policy" "service_account_policy" {
  for_each = local.service_accounts

  name        = "${var.cluster_name}-${var.namespace}-${each.key}-policy"
  description = "IAM policy for ${each.key} service account in ${var.namespace} namespace"
  policy      = each.value.policy_document
}

# Create IAM role for each service account
resource "aws_iam_role" "service_account_role" {
  for_each = local.service_accounts

  name = "${var.cluster_name}-${var.namespace}-${each.key}-role"
  
  # Trust relationship policy that allows the service account to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub": "system:serviceaccount:${var.namespace}:${each.key}"
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:aud": "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Namespace   = var.namespace
    ServiceAccount = each.key
    ManagedBy   = "terraform"
  }
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "service_account_role_policy_attachment" {
  for_each = local.service_accounts

  role       = aws_iam_role.service_account_role[each.key].name
  policy_arn = aws_iam_policy.service_account_policy[each.key].arn
}

# Annotate existing Kubernetes service accounts with IAM role ARN
resource "kubernetes_annotations" "service_account_annotations" {
  for_each = local.service_accounts

  api_version = "v1"
  kind        = "ServiceAccount"
  metadata {
    name      = each.key
    namespace = var.namespace
  }
  annotations = {
    "eks.amazonaws.com/role-arn" = aws_iam_role.service_account_role[each.key].arn
  }

  # Force annotations to be applied after roles are created
  depends_on = [aws_iam_role_policy_attachment.service_account_role_policy_attachment]
}

# Get AWS account ID
data "aws_caller_identity" "current" {}

# Get EKS cluster data for OIDC provider
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}
