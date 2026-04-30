resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  key_name                    = var.key_name
  vpc_security_group_ids      = var.security_group_ids
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name      = var.app_name
    App       = var.app_name
    CreatedBy = var.created_by
  }
}

/* # Optional scheduling for EC2
# prerequisite: EC2 scheduler role with "StartStopEC2Instances" policy:
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Sid": "VisualEditor0",
#             "Effect": "Allow",
#             "Action": [
#                 "ec2:StartInstances",
#                 "ec2:StopInstances"
#             ],
#             "Resource": "*"
#         }
#     ]
# }
# and the following trust policy:
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Allow",
#             "Principal": {
#                 "Service": "scheduler.amazonaws.com"
#             },
#             "Action": "sts:AssumeRole"
#         }
#     ]
# }

data "aws_iam_role" "ec2_scheduler_role" {
  name = "EC2Scheduler"
}

# Schedule: Start Instance
resource "aws_scheduler_schedule" "start_ec2" {
  name       = var.start_ec2_schedule_name
  group_name = var.group_name

  schedule_expression          = var.start_ec2_schedule_expression
  schedule_expression_timezone = "Asia/Jerusalem" # Adjust as needed

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
    role_arn = data.aws_iam_role.ec2_scheduler_role.arn

    input = jsonencode({
      InstanceIds = [
        aws_instance.instance.id
      ]
    })
  }
}

# Schedule: Stop Instance
resource "aws_scheduler_schedule" "stop_ec2" {
  name       = var.stop_ec2_schedule_name
  group_name = var.group_name

  schedule_expression          = var.stop_ec2_schedule_expression
  schedule_expression_timezone = "Asia/Jerusalem"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = data.aws_iam_role.ec2_scheduler_role.arn

    input = jsonencode({
      InstanceIds = [
        aws_instance.instance.id
      ]
    })
  }
}
*/