resource "terraform_data" "build_and_push_images" {
  for_each = local.ecs_services

  triggers_replace = {
    always_run = timestamp()
  }
  depends_on = [module.ecs_stack]

  provisioner "local-exec" {
    command = "bash scripts/build_push_images.sh"
    environment = {
      service_name = each.key
      repo_url     = module.ecs_stack[each.key].ecr_url
      image_tag    = var.image_tag
      region       = var.region
    }
  }
}