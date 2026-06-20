output "target_iam_role_arn" {
  value       = aws_iam_role.github_actions_ecr.arn
  description = "Copy this exact string into your GitHub YAML file"
}