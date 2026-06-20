variable "env" {
  description = "The environment to deploy to"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "Region of AWS to deploy the resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "ipv4 CIDR range for vpc for example: 10.0.0.0/16"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_public_count" {
  description = "Number of public subnets to create, it will also create the same amount of az's"
  type        = number
  default     = 2
}

variable "subnet_private_count" {
  description = "Number of private subnets to create, it will also create the same amount of az's"
  type        = number
  default     = 2
}

variable "allowed_protocols_sg" {
  description = "Protocols allows in the security group rules"
  type        = map(string)
  default = {
    22 = "tcp"
    80 = "tcp"
    -1 = "icmp" # -1 means all ports
  }
}

variable "allowed_protocols_sg_alb" {
  description = "Protocols allows in the security group rules"
  type        = map(string)
  default = {
    80 = "tcp"
  }
}

variable "project_name" {
  type    = string
  default = "default-project-name" # Do not use underscores (_) some resources reject it
}

variable "desired_task_count" {
  description = "Number of desired tasks to run in a ecs service"
  type        = number
  default     = 2
}

variable "bucket_name" {
  type        = string
  description = "the name of the state bucket" 
  default     = "state-prod-default-project-name"
}

variable "image_tag" {
  type = string
  description = "The image tag gh action will push to ecr and update task definition"
  default = "latest"
}