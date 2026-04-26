resource "aws_lb" "this" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.subnet_ids

  tags = {
    Name      = "${var.app_name}-alb"
    App       = var.app_name
    CreatedBy = var.created_by
  }
}

resource "aws_lb_target_group" "this" {
  name     = "${var.app_name}-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/api/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name      = "${var.app_name}-tg"
    App       = var.app_name
    CreatedBy = var.created_by
  }
}

resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = var.ec2_instance_id
  port             = 3000
}

# HTTP listener — redirects all traffic to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      status_code = "HTTP_301"
      port        = "443"
      protocol    = "HTTPS"
    }
  }
}

# Optional: add listener for grafana. Use GRAFANA_ROOT_URL env variable for the Grafana container.
# resource "aws_lb_target_group" "grafana" {
#   name     = "${var.app_name}-grafana-tg"
#   port     = 3020
#   protocol = "HTTP"
#   vpc_id   = var.vpc_id

#   health_check {
#     path                = "/api/health"
#     protocol            = "HTTP"
#     matcher             = "200"
#     interval            = 30
#     timeout             = 10
#     healthy_threshold   = 2
#     unhealthy_threshold = 3
#   }

#   tags = {
#     Name      = "${var.app_name}-grafana-tg"
#     App       = var.app_name
#     CreatedBy = var.created_by
#   }
# }

# resource "aws_lb_target_group_attachment" "grafana" {
#   target_group_arn = aws_lb_target_group.grafana.arn
#   target_id        = var.ec2_instance_id
#   port             = 3020
# }

# HTTPS listener — forwards traffic to the app on port 3000
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
