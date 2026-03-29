variable "app_name" {
  description = "Application name used for ALB and target group naming"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the target group"
  type        = string
}

variable "subnet_ids" {
  description = "Public subnet IDs for the ALB (minimum 2, across different AZs)"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID to attach to the ALB"
  type        = string
}

variable "ec2_instance_id" {
  description = "EC2 instance ID to register in the target group"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the validated ACM certificate for the HTTPS listener"
  type        = string
}

variable "created_by" {
  description = "Tag value for who created the resource"
  type        = string
  default     = "Terraform"
}
