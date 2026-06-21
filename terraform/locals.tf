locals {
  env           = terraform.workspace
  resource_name = "${local.env}-${var.project_name}"

  vpc_id             = module.network_infra.vpc_id
  private_subnet_ids = module.network_infra.private_subnets
  public_subnet_ids  = module.network_infra.public_subnets

  security_group_tasks = module.network_infra.security_group_tasks
  security_group_alb   = module.network_infra.security_group_alb


  target_group_arn = module.alb.target_groups["ecs_tasks"].arn
}

locals {
  ecs_services = { 
    nginx-docker = { # the services key has to match the dirs in service/
      desired_count    = 2
      min_tasks        = 2
      max_tasks        = 4
      cpu_percentage   = 60
      target_group_arn = module.alb.target_groups["ecs_tasks"].arn
      env_vars         = {
        API_URL = "api-service.local"
      }
    },
    api-service = {
      desired_count    = 2
      min_tasks        = 3
      max_tasks        = 4
      cpu_percentage   = 60
      target_group_arn = ""
      env_vars         = {
        API_URL = "api-service.local"
      }
    }
  }
}