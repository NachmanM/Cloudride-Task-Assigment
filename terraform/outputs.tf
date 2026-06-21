output "vpc_id" {
  value = module.network_infra.vpc_id
}

output "private_subnets" {
  value = module.network_infra.private_subnets
}

output "public_subnets" {
  value = module.network_infra.public_subnets
}

output "security_group_tasks" {
  value = module.network_infra.security_group_tasks
}

output "security_group_alb" {
  value = module.network_infra.security_group_alb
}

output "ecr_repo_url" {
  value = [for s in module.ecs_stack : s.ecr_url]
}

output "oidc_iam_role" {
  value       = module.aws_oidc.target_iam_role_arn
  description = "Copy this exact string into your GitHub YAML file"
}

output "state_bucket_name" {
  value = module.s3_state.state_bucket_name
}