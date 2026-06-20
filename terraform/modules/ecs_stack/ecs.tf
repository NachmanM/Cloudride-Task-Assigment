resource "aws_ecr_repository" "main" {
  name                 = var.resource_name
  image_tag_mutability = "IMMUTABLE_WITH_EXCLUSION"

  image_tag_mutability_exclusion_filter {
    filter      = "latest*"
    filter_type = "WILDCARD"
  }
  force_delete = true
}

resource "aws_ecs_task_definition" "main" {
  family                   = var.resource_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::753392824297:role/cloudride-challenge-app-ecsTaskExecutionRole"

  runtime_platform {
    operating_system_family = "LINUX"
  }
  container_definitions = jsonencode([
  {
    name      = "hello-world-nachman"
    image     = "${aws_ecr_repository.main.repository_url}:${var.image_tag}"
    essential = true
    
    portMappings = [
      {
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
      }
    ]
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }
])
}

resource "aws_ecs_cluster" "main" {
  name = var.resource_name
}

resource "aws_ecs_service" "main" {
  name            = var.resource_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.id
  desired_count   = var.desired_task_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.tasks_security_groups]
    assign_public_ip = false
  }

  load_balancer {
    # Reference the target group ARN from the ALB module output maps
    target_group_arn = var.target_group_arn
    container_name   = "hello-world-nachman"
    container_port   = 80
  }

  force_new_deployment = true
  triggers = {
    redployment = plantimestamp()
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.resource_name}"
  retention_in_days = 30
}