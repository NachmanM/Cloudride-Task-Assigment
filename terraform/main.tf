module "network_infra" {
  source                   = "./modules/network_infra"
  env                      = local.env
  vpc_cidr                 = var.vpc_cidr
  subnet_public_count      = var.subnet_public_count
  subnet_private_count     = var.subnet_private_count
  allowed_protocols_sg     = var.allowed_protocols_sg
  allowed_protocols_sg_alb = var.allowed_protocols_sg_alb
  resource_name            = local.resource_name
}

module "s3_state" {
  source      = "./modules/s3_state"
  bucket_name = var.bucket_name
}

module "aws_oidc" {
  source           = "./modules/aws_oidc"
  state_bucket_arn = module.s3_state.state_bucket_arn
  env              = local.env
  resource_name    = local.resource_name
}

module "ecs_cluster_wide" {
  source        = "./modules/ecs_cluster_wide"
  resource_name = local.resource_name
}
module "ecs_stack" {
  source                = "./modules/ecs_stack"
  resource_name         = local.resource_name
  private_subnet_ids    = local.private_subnet_ids
  tasks_security_groups = local.security_group_tasks
  for_each              = local.ecs_services
  desired_task_count    = each.value["desired_count"]
  service_name          = each.key
  min_tasks             = each.value["min_tasks"]
  max_tasks             = each.value["max_tasks"]
  cpu_percentage        = each.value["cpu_percentage"]
  target_group_arn      = each.value["target_group_arn"]
  env_vars              = each.value["env_vars"]

  region        = var.region
  image_tag     = var.image_tag
  namespace_arn = module.ecs_cluster_wide.namespace_arn
  cluster_id    = module.ecs_cluster_wide.cluster_id
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = "alb-${local.resource_name}"
  vpc_id  = local.vpc_id
  subnets = local.public_subnet_ids

  create_security_group      = false
  security_groups            = [local.security_group_alb]
  enable_deletion_protection = false

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "ecs_tasks"
      }
    }
  }

  target_groups = {
    ecs_tasks = {
      name_prefix       = "ecs-"
      protocol          = "HTTP"
      port              = 80
      target_type       = "ip"
      create_attachment = false
    }
  }
}