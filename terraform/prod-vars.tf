variable "env" {
  description = "The environment to deploy to"
  type        = string
  default     = "prod"
}

variable "subnet_public_count" {
    description = "Number of public subnets to create, it will also create the same amount of az's"
    type = number
    default = 2
}

variable "subnet_private_count" {
    description = "Number of private subnets to create, it will also create the same amount of az's"
    type = number
    default = 2
}

variable "allowed_protocols_sg" {
    description = "Protocols allows in the security group rules"
    type = map(string)
    default = {
        22 = "tcp"
        80 = "tcp"
        -1 = "icmp" # -1 means all ports
    }
}