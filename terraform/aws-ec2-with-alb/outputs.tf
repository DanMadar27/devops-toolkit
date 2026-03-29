# Run `terraform output acm_validation_records` to get the CNAME records
# that the albarius.io DNS owner must add before the certificate will be issued.
output "acm_validation_records" {
  description = "CNAME records to give the albarius.io DNS owner for SSL certificate validation"
  value       = module.acm.validation_records
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.load_balancer.alb_dns_name
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = module.compute.instance_id
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = module.compute.public_ip
}

output "ec2_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = module.compute.private_ip
}

output "key_pair_name" {
  description = "Name of the AWS key pair attached to the EC2 instance"
  value       = module.key_pair.key_name
}

output "private_key_pem" {
  description = "PEM-encoded private key for SSH access - run: terraform output -raw private_key_pem > key.pem && chmod 600 key.pem"
  value       = module.key_pair.private_key_pem
  sensitive   = true
}
