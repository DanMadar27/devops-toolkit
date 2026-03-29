variable "app_name" {
  description = "Application name used for security group naming"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to create security groups in"
  type        = string
}

variable "created_by" {
  description = "Tag value for who created the resource"
  type        = string
  default     = "Terraform"
}
