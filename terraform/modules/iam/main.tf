# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-${var.environment}-ecs-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ecs-task-execution"
  })
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Policy for task execution role to access Secrets Manager (needed for container startup)
resource "aws_iam_policy" "task_execution_secrets" {
  name        = "${var.project_name}-${var.environment}-task-execution-secrets"
  description = "Policy for ECS task execution role to access secrets during container startup"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.secret_arns
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-task-execution-secrets"
  })
}

# Attach secrets policy to task execution role
resource "aws_iam_role_policy_attachment" "task_execution_secrets" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.task_execution_secrets.arn
}

# ECS Task Role for Backend (with Secrets Manager access)
resource "aws_iam_role" "ecs_task_backend" {
  name = "${var.project_name}-${var.environment}-ecs-task-backend"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ecs-task-backend"
  })
}

# Policy for backend to access Secrets Manager
resource "aws_iam_policy" "secrets_access" {
  name        = "${var.project_name}-${var.environment}-secrets-access"
  description = "Policy for backend service to access specific secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.secret_arns
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-secrets-access"
  })
}

# Attach secrets policy to backend task role
resource "aws_iam_role_policy_attachment" "backend_secrets" {
  role       = aws_iam_role.ecs_task_backend.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

# ECS Task Role for Frontend (minimal permissions)
resource "aws_iam_role" "ecs_task_frontend" {
  name = "${var.project_name}-${var.environment}-ecs-task-frontend"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ecs-task-frontend"
  })
}