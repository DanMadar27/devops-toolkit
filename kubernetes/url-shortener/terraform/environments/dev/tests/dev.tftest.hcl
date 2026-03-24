variables {
  key_name  = "test-key"
  vpc_id    = "vpc-00000000000000000"
  subnet_id = "subnet-00000000000000000"
}

run "ec2_instance_type_is_t3_medium" {
  command = plan
  expect_failures = [check.ec2_running] # command is planned, so expect_failures is used to skip the check

  assert {
    condition     = var.instance_type == "t3.medium"
    error_message = "EC2 instance type must be t3.medium"
  }
}

run "ecr_repositories_created" {
  command = plan

  expect_failures = [check.ec2_running] # command is planned, so expect_failures is used to skip the check

  override_resource {
    target = module.ecr.aws_ecr_repository.shorten
    values = {
      repository_url = "<account-id>.dkr.ecr.eu-central-1.amazonaws.com/url-shortener/shorten"
    }
  }

  override_resource {
    target = module.ecr.aws_ecr_repository.redirect
    values = {
      repository_url = "<account-id>.dkr.ecr.eu-central-1.amazonaws.com/url-shortener/redirect"
    }
  }

  assert {
    condition     = module.ecr.shorten_repo_url != ""
    error_message = "Shorten ECR repository was not created"
  }

  assert {
    condition     = module.ecr.redirect_repo_url != ""
    error_message = "Redirect ECR repository was not created"
  }
}
