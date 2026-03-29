variable "app_name" {
  description = "Application name used for key pair naming"
  type        = string
}

variable "created_by" {
  description = "Tag value for who created the resource"
  type        = string
  default     = "Terraform"
}
