output "key_name" {
  description = "Name of the AWS key pair"
  value       = aws_key_pair.this.key_name
}

output "private_key_pem" {
  description = "PEM-encoded RSA private key"
  value       = tls_private_key.this.private_key_pem
  sensitive   = true
}
