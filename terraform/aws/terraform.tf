terraform {
  # Configure remote state in S3 (with enabled versioning)
  /*
  You can create lifecycle rule:
    - name: delete_old_versions
    - Scope: Entire bucket
    - Noncurrent versions actions:
      - day 30: 
          - 2 newest noncurrent versions are retained
          - All other noncurrent versions are permanently deleted
    - Delete expired object delete markers or incomplete multipart uploads
        - Delete expired object delete markers
        - Incomplete multipart uploads: Delete after 30 days
  */
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