variable "domain_name" {
  description = "Domain name for the SSL certificate and HTTPS listener"
  type        = string
  default     = "example.com"
}

variable "created_by" {
  description = "Created by"
  type        = string
  default     = "Terraform"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "app_name" {
  description = "Application name used for resource naming and tagging"
  type        = string
  default     = "example-app"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "vpc_id" {
  description = "Existing VPC ID to deploy resources into"
  type        = string
}

variable "alb_subnet_ids" {
  description = "List of public subnet IDs for the ALB (minimum 2, across different AZs)"
  type        = list(string)
}

variable "ec2_subnet_id" {
  description = "Subnet ID for the EC2 instance"
  type        = string
}

