resource "aws_ecr_repository" "main" {
    name    = "${var.env}-${var.project_name}"
    image_tag_mutability = "IMMUTABLE_WITH_EXCLUSION"

    image_tag_mutability_exclusion_filter {
        filter      = "latest*"
        filter_type = "WILDCARD"
    }
}

resource "aws_ecs_task_definition" "main" {
  family                   = "fargate-task-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::753392824297:role/cloudride-challenge-app-ecsTaskExecutionRole"

  runtime_platform {
    operating_system_family = "LINUX"
  }
  container_definitions = file("task-definitions/nginx-docker.json")
}

resource "aws_ecs_cluster" "main" {
  name = "${local.resource_name}"
}