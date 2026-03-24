check "ec2_running" {
  assert {
    condition     = module.ec2.instance_state == "running"
    error_message = "EC2 instance is not in running state"
  }
}
