output "shorten_repo_url" {
  description = "ECR repository URL for the shorten service"
  value       = aws_ecr_repository.shorten.repository_url
}

output "redirect_repo_url" {
  description = "ECR repository URL for the redirect service"
  value       = aws_ecr_repository.redirect.repository_url
}
