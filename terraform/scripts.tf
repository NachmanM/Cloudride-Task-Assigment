resource "terraform_data" "replace_task_definition_json_script" {
  triggers_replace = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "python ../scripts/replace-vars-json.py"
    environment = {
      resource_name        = local.resource_name
      repo_url             = module.ecs_stack.ecr_url
      cloudwatch_log_group = module.ecs_stack.cloudwatch_log_group
      region               = var.region
      image_tag            = var.image_tag
    }
  }
}