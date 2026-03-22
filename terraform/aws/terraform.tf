terraform {
  # Configure remote state in S3
  #   backend "s3" {
  #   bucket       = "bucket-name"
  #   key          = "path/terraform.tfstate"
  #   region       = "region-name"
  #   use_lockfile = true # Lock file is used to prevent race conditions when multiple terraform processes try to access the same state file.
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.35"
    }
  }

  required_version = ">= 1.1"
}

provider "aws" {
  region = "eu-central-1"
}