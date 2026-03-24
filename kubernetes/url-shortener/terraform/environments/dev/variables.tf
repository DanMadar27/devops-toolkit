variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
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

variable "vpc_id" {
  description = "ID of an existing VPC"
  type        = string
}

variable "subnet_id" {
  description = "ID of an existing public subnet"
  type        = string
}
