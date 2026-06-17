module "network_infra" {
    source = "./modules/network_infra"
    env = var.env
    vpc_cidr = var.vpc_cidr
    subnet_public_count = var.subnet_public_count
    subnet_private_count = var.subnet_private_count
    allowed_protocols_sg = var.allowed_protocols_sg
    resource_name        = local.resource_name
}