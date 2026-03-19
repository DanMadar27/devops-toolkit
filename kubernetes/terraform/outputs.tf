output "cluster_id" {
  description = "The EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for your EKS Kubernetes API server"
  value       = module.eks.cluster_endpoint
}

output "node_group_role_arn" {
  description = "The ARN of the node group IAM role"
  value       = module.eks.eks_managed_node_groups["spot_nodes"].iam_role_arn
}

output "cluster_security_group_id" {
  description = "Security group id attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "nginx_status" {
  value = helm_release.nginx.status
}

output "nginx_version" {
  value = helm_release.nginx.version
}

output "nginx_namespace" {
  value = helm_release.nginx.namespace
}
