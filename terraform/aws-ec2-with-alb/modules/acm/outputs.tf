output "certificate_arn" {
  description = "Validated ACM certificate ARN — only available after DNS validation completes"
  value       = aws_acm_certificate_validation.this.certificate_arn
}

# Use `terraform output acm_validation_records` to get the CNAME records
# that must be added to DNS before the certificate will be issued.
output "validation_records" {
  description = "CNAME records to add to DNS for certificate validation"
  value = {
    for record in aws_acm_certificate.this.domain_validation_options : record.domain_name => {
      name  = record.resource_record_name
      type  = record.resource_record_type
      value = record.resource_record_value
    }
  }
}
