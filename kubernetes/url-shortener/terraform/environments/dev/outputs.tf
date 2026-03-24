output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.ec2.public_ip
}

output "shorten_repo_url" {
  description = "ECR repository URL for the shorten service"
  value       = module.ecr.shorten_repo_url
}

output "redirect_repo_url" {
  description = "ECR repository URL for the redirect service"
  value       = module.ecr.redirect_repo_url
}
