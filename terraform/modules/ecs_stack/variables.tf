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
  default     = ""
}

variable "region" {
  type = string
}

variable "image_tag" {
  type = string
}

variable "service_name" {
  type = string
}

variable "min_tasks" {
  type = number
}

variable "max_tasks" {
  type = number
}

variable "cpu_percentage" {
  type = number
}

variable "namespace_arn" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "env_vars" {
  type = map(string)
}