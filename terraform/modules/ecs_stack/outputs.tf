output "ecr_url" {
    value = aws_ecr_repository.main.repository_url
}

output "cloudwatch_log_group" {
    value = aws_cloudwatch_log_group.ecs.name
}