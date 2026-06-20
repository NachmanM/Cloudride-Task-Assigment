variable "resource_name" {
  type    = string
  default = "default_project_name"
}

variable "desired_task_count" {
  description = "Number of desired tasks to run in a ecs service"
  type        = number
  default     = 2
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "tasks_security_groups" {
  type = string
}

variable "target_group_arn" {
  type        = string
  description = "Connects ecs tasks to alb"
}

variable "region" {
  type = string
}

variable "image_tag" {
  type = string
}