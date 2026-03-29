resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = "${var.app_name}-key"
  public_key = tls_private_key.this.public_key_openssh

  tags = {
    Name      = "${var.app_name}-key"
    App       = var.app_name
    CreatedBy = var.created_by
  }
}
