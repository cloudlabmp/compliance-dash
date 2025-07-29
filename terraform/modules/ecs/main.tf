# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}"

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-cluster"
  })
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.project_name}-${var.environment}-frontend"
  retention_in_days = 7

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-frontend-logs"
  })
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}-${var.environment}-backend"
  retention_in_days = 7

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-backend-logs"
  })
}

# Service Discovery Namespace
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.project_name}-${var.environment}.local"
  description = "Service discovery namespace for ${var.project_name}-${var.environment}"
  vpc         = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-discovery"
  })
}

# Service Discovery Service for Backend
resource "aws_service_discovery_service" "backend" {
  name = "backend"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }


  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-backend-discovery"
  })
}

# ECS Task Definition for Frontend
resource "aws_ecs_task_definition" "frontend" {
  family             = "${var.project_name}-${var.environment}-frontend"
  network_mode       = "awsvpc"
  cpu                = "256"
  memory             = "512"
  execution_role_arn = var.ecs_task_execution_role_arn
  task_role_arn      = var.ecs_task_frontend_role_arn

  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = var.container_images["frontend"]
      essential = true

      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "REACT_APP_API_URL"
          value = "http://backend.${var.project_name}-${var.environment}.local:3001"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.frontend.name
          "awslogs-region"        = data.aws_region.current.region
          awslogs-stream-prefix = "ecs"
        }
      }

      healthCheck = {
        command = ["CMD-SHELL", "curl -f http://localhost:3000/ || exit 1"]
        interval = 30
        timeout = 5
        retries = 3
        startPeriod = 60
      }
    }
  ])

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-frontend-task"
  })
}

# ECS Task Definition for Backend
resource "aws_ecs_task_definition" "backend" {
  family             = "${var.project_name}-${var.environment}-backend"
  network_mode       = "awsvpc"
  cpu                = "256"
  memory             = "512"
  execution_role_arn = var.ecs_task_execution_role_arn
  task_role_arn      = var.ecs_task_backend_role_arn

  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = var.container_images["backend"]
      essential = true

      portMappings = [
        {
          containerPort = 3001
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "PORT"
          value = "3001"
        }
      ]

      secrets = [
        {
          name      = "OPENAI_API_KEY"
          valueFrom = var.secret_arns["backend-openai-key"]
        },
        {
          name      = "AWS_CREDENTIALS"
          valueFrom = var.secret_arns["backend-aws-credentials"]
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.backend.name
          "awslogs-region"        = data.aws_region.current.region
          awslogs-stream-prefix = "ecs"
        }
      }

      healthCheck = {
        command = ["CMD-SHELL", "curl -f http://localhost:3001/health || exit 1"]
        interval = 30
        timeout = 5
        retries = 3
        startPeriod = 60
      }
    }
  ])

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-backend-task"
  })
}

# ECS Service for Frontend
resource "aws_ecs_service" "frontend" {
  name            = "${var.project_name}-${var.environment}-frontend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [var.ecs_security_group_id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.frontend_target_group_arn
    container_name   = "frontend"
    container_port   = 3000
  }

  depends_on = [var.frontend_target_group_arn]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-frontend-service"
  })
}

# ECS Service for Backend
resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-${var.environment}-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [var.ecs_security_group_id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.backend_target_group_arn
    container_name   = "backend"
    container_port   = 3001
  }

  service_registries {
    registry_arn = aws_service_discovery_service.backend.arn
  }

  depends_on = [var.backend_target_group_arn]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-backend-service"
  })
}

# Data source for current region
data "aws_region" "current" {}