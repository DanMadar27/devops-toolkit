terraform {
  # Configure remote state in S3
  backend "s3" {
    bucket       = "bucket-name"
    key          = "path/terraform.tfstate"
    region       = "region-name"
    use_lockfile = true # Lock file is used to prevent race conditions when multiple terraform processes try to access the same state file.
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.35"
    }
  }
}

provider "aws" {
  region = var.region
}

module "ec2" {
  source        = "../../modules/ec2"
  vpc_id        = var.vpc_id
  subnet_id     = var.subnet_id
  instance_type = var.instance_type
  key_name      = var.key_name
  environment   = var.environment
}

module "ecr" {
  source      = "../../modules/ecr"
  environment = var.environment
}
