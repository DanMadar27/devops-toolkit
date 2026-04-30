variable "app_name" {
  description = "Application name used for instance naming and tagging"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to launch the EC2 instance in"
  type        = string
}

variable "key_name" {
  description = "Name of the AWS key pair for SSH access"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the EC2 instance"
  type        = list(string)
}

variable "created_by" {
  description = "Tag value for who created the resource"
  type        = string
  default     = "Terraform"
}

/*
# Scheduler variables (optional)
variable "start_ec2_schedule_name" {
  description = "The name of the start EC2 schedule."
  type        = string
}

variable "stop_ec2_schedule_name" {
  description = "The name of the stop EC2 schedule."
  type        = string
  default     = "apartments-stop-ec2-daily-sun-fri"
}

variable "group_name" {
  description = "The name of the group name."
  type        = string
  default     = "default"
}

variable "start_ec2_schedule_expression" {
  description = "The schedule expression."
  type        = string
  # default     = "cron(0 8 ? * SUN-FRI *)" # 08:00 AM, Sunday to Friday
}

variable "stop_ec2_schedule_expression" {
  description = "The schedule expression."
  type        = string
  # default     = "cron(0 20 ? * SUN-FRI *)" # 08:00 PM, Sunday to Friday
}
*/