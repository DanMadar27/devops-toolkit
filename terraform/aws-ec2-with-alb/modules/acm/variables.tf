variable "domain_name" {
  description = "Domain name for the SSL certificate (e.g. project.com)"
  type        = string
}

variable "app_name" {
  description = "Application name used for tagging"
  type        = string
}

variable "created_by" {
  description = "Tag value for who created the resource"
  type        = string
  default     = "Terraform"
}
