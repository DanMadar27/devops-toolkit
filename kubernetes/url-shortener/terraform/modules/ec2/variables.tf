variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Name of an existing AWS key pair to use for SSH access"
  type        = string
}

variable "iam_instance_profile" {
  description = "Name of an existing IAM instance profile to attach to the EC2 instance"
  type        = string
  default     = "ReadECR"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}
