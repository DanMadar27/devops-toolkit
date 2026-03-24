terraform {
  cloud {
    organization = "<your-org-name>"
    workspaces {
      name = "url-shortener-dev"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source      = "../../modules/vpc"
  environment = var.environment
}

module "ec2" {
  source        = "../../modules/ec2"
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.subnet_id
  instance_type = var.instance_type
  public_key    = var.public_key
  environment   = var.environment
}

module "ecr" {
  source      = "../../modules/ecr"
  environment = var.environment
}
