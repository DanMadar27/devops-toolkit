terraform {
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