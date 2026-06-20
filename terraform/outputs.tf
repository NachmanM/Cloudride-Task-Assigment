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
  value = module.ecs_stack.ecr_url
}