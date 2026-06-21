terraform {
  required_version = "1.15.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.50.0"
    }
  }
}


resource "aws_service_discovery_http_namespace" "main" {
  name        = var.resource_name
  description = "Cloud Map namespace for ECS Service Connect"
}

resource "aws_ecs_cluster" "main" {
  name = var.resource_name
}


variable "resource_name" {
  type = string
}

output "namespace_arn" {
  value = aws_service_discovery_http_namespace.main.arn
}

output "cluster_id" {
    value = aws_ecs_cluster.main.id
}