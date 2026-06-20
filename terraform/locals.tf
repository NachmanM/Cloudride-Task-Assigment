locals {
  resource_name = "${var.env}-${var.project_name}"

  vpc_id             = module.network_infra.vpc_id
  private_subnet_ids = module.network_infra.private_subnets
  public_subnet_ids  = module.network_infra.public_subnets

  security_group_tasks = module.network_infra.security_group_tasks
  security_group_alb   = module.network_infra.security_group_alb


  target_group_arn = module.alb.target_groups["ecs_tasks"].arn
}