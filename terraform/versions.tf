terraform {
  required_version = "1.15.6"

  backend "s3" {
    bucket       = "state-prod-default-project-name"
    key          = "prod/nachman-state.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.50.0"
    }
  }
}


provider "aws" {
  region  = var.region
  profile = "cloudride" # Set in ~/.aws/credentials
  default_tags {
    tags = {
      ManagedBy = "NachmanTerraform"
      env       = var.env
      Name      = "${var.project_name}-${var.env}"
    }
  }
}
