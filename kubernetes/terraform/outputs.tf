output "cluster_id" {
  description = "The EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for your EKS Kubernetes API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "node_group_role_arn" {
  description = "The ARN of the node group IAM role"
  value       = module.eks.eks_managed_node_groups["spot_nodes"].iam_role_arn
}

output "cluster_security_group_id" {
  description = "Security group id attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "kubectl_config" {
  description = "A block of configuration to use with kubectl to connect to the cluster"
  value = {
    endpoint               = module.eks.cluster_endpoint
    cluster_ca_certificate = module.eks.cluster_certificate_authority_data
    cluster_name           = module.eks.cluster_name
  }
}