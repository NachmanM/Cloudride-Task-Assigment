resource "aws_ecr_repository" "main" {
  name                 = "${var.resource_name}-${var.service_name}"
  image_tag_mutability = "IMMUTABLE_WITH_EXCLUSION"

  image_tag_mutability_exclusion_filter {
    filter      = "latest*"
    filter_type = "WILDCARD"
  }
  force_delete = true
}

resource "aws_ecs_task_definition" "main" {
  family                   = var.service_name
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
          name          = "default-port-name"
        }
      ]

      environment = [
        for key, value in var.env_vars : {
          name  = key
          value = value
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

resource "aws_ecs_service" "main" {
  name            = var.service_name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.main.id
  desired_count   = var.desired_task_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.tasks_security_groups]
    assign_public_ip = false
  }
  service_connect_configuration {
    enabled   = true
    namespace = var.namespace_arn

    service {
      discovery_name = var.service_name
      client_alias {
        port     = 80
        dns_name = "${var.service_name}.local"
      }
      port_name = "default-port-name" # Must match task definition portMappings
    }
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn != "" ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = "hello-world-nachman"
      container_port   = 80
    }
  }

  force_new_deployment = true
  triggers = {
    redployment = plantimestamp()
  }
  lifecycle {
    replace_triggered_by = [aws_ecs_task_definition.main]
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.resource_name}-${var.service_name}"
  retention_in_days = 30
}

resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.max_tasks
  min_capacity       = var.min_tasks
  resource_id        = "service/${var.resource_name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.resource_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = "${var.cpu_percentage}.0"
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}