# VPC variables
variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "The IDs of the subnets"
  type        = list(string)
}

# Cluster variables
variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "practice-eks"
}

variable "cluster_version" {
  description = "The version of the EKS cluster"
  type        = string
  default     = "1.33"
}

variable "eks_node_instance_types" {
  description = "The EKS managed node instance types"
  type        = list(string)
  default     = ["t3.medium", "t3.small"]
}

variable "eks_node_min_size" {
  description = "The EKS managed node minimum size"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "The EKS managed node maximum size"
  type        = number
  default     = 3
}

variable "eks_node_desired_size" {
  description = "The EKS managed node desired size"
  type        = number
  default     = 2
}

variable "grafana_admin_user" {
  description = "Grafana admin user"
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}
