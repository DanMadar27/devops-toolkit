# Configure the Azure provider
terraform {
  # Configure remote state in Azure
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "terraformbackend123415" # must be globally unique — change if taken
  #   container_name       = "tfstate"
  #   key                  = "azure-terraform.tfstate"
  #   use_oidc             = true # uses az login / service principal — no storage key stored
  # }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.63"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}
