# Get AWS account ID
data "aws_caller_identity" "current" {}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  # Convert prefix to lowercase for ECR compatibility

  # Use var.image_name_passed_as_parameter directly
  ecr_repo = lower(var.image_name_passed_as_parameter)
  ecr_image_url = "${local.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.ecr_repo}"
  log_group_name = "/ecs/${var.prefix}"
}

# Execution role for ECS
resource "aws_iam_role" "execution_role" {
  name = "${var.prefix}-execution-role"

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
}

resource "aws_iam_role_policy_attachment" "execution_role_policy" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task role for ECS
resource "aws_iam_role" "task_role" {
  name = "${var.prefix}-task-role"

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
}

# CloudWatch log group
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = local.log_group_name
  retention_in_days = 30

  tags = {
    Name        = "${var.prefix}-logs"
    Environment = var.environment
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.prefix}-task"
  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 2048    # 2 vCPU (2048 CPU units)
  memory                   = 8192    # 8 GB RAM (8192 MiB)
  
  # Specify ARM64 architecture for Fargate
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name      = "${var.prefix}-container"
      image     = "${local.ecr_image_url}:latest"
      essential = true
      
      portMappings = [
        # Port range 2800-3300
        {
          containerPort = 2800
          hostPort      = 2800
          protocol      = "tcp"
        },
        {
          containerPort = 2801
          hostPort      = 2801
          protocol      = "tcp"
        },
        # More ports in the range can be added as needed
        {
          containerPort = 3300
          hostPort      = 3300
          protocol      = "tcp"
        },
        # Port 5222
        {
          containerPort = 5222
          hostPort      = 5222
          protocol      = "tcp"
        },
        # Port 80
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        },
        # Port 443
        {
          containerPort = 443
          hostPort      = 443
          protocol      = "tcp"
        },
        # Port 22
        {
          containerPort = 22
          hostPort      = 22
          protocol      = "tcp"
        },
        # Original port 8080
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = local.log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      
      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        }
      ]
    }
  ])

  tags = {
    Name        = "${var.prefix}-task"
    Environment = var.environment
  }
} 