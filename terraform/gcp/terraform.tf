terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.23"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}
