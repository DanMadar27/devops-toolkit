variables {
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0 test-key"
}

run "vpc_cidr_is_correct" {
  command = plan

  assert {
    condition     = module.vpc.vpc_id != ""
    error_message = "VPC was not created"
  }
}

run "ec2_instance_type_is_t3_medium" {
  command = plan

  assert {
    condition     = var.instance_type == "t3.medium"
    error_message = "EC2 instance type must be t3.medium"
  }
}

run "ecr_repositories_created" {
  command = plan

  assert {
    condition     = module.ecr.shorten_repo_url != ""
    error_message = "Shorten ECR repository was not created"
  }

  assert {
    condition     = module.ecr.redirect_repo_url != ""
    error_message = "Redirect ECR repository was not created"
  }
}
