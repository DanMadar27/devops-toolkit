terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.35"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }

  required_version = ">= 1.1"
}

provider "aws" {
  region = "eu-central-1"
}

# https://registry.terraform.io/providers/hashicorp/helm/latest/docs#credentials-config
provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}