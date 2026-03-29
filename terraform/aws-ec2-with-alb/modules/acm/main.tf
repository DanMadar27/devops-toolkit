resource "aws_acm_certificate" "this" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  # Required when replacing a certificate already in use by a listener.
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name      = var.domain_name
    App       = var.app_name
    CreatedBy = var.created_by
  }
}

# Waits until the certificate status becomes ISSUED.
# Terraform will block here (up to 45 min) until the CNAME records below
# have been added to DNS and propagated.
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_acm_certificate.this.domain_validation_options : record.resource_record_name]
}
