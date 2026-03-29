module "acm" {
  source      = "./modules/acm"
  domain_name = var.domain_name
  app_name    = var.app_name
  created_by  = var.created_by
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "key_pair" {
  source     = "./modules/key_pair"
  app_name   = var.app_name
  created_by = var.created_by
}

module "security_groups" {
  source     = "./modules/security_groups"
  app_name   = var.app_name
  vpc_id     = var.vpc_id
  created_by = var.created_by
}

module "compute" {
  source             = "./modules/compute"
  app_name           = var.app_name
  ami_id             = data.aws_ami.ubuntu.id
  instance_type      = var.instance_type
  subnet_id          = var.ec2_subnet_id
  key_name           = module.key_pair.key_name
  security_group_ids = [module.security_groups.ec2_security_group_id]
  created_by         = var.created_by
}

module "load_balancer" {
  source              = "./modules/load_balancer"
  app_name            = var.app_name
  vpc_id              = var.vpc_id
  subnet_ids          = var.alb_subnet_ids
  security_group_id   = module.security_groups.alb_security_group_id
  ec2_instance_id     = module.compute.instance_id
  acm_certificate_arn = module.acm.certificate_arn
  created_by          = var.created_by
}
