locals {
  # ALB and target group names are limited to 32 characters.
  lb_name = substr(lower(replace(var.name, "/[^a-zA-Z0-9-]/", "-")), 0, 32)
  tg_name = substr("${local.lb_name}-tg", 0, 32)

  protocol = var.enable_https ? "https" : "http"
  host     = var.enable_https && var.domain_name != null ? var.domain_name : aws_lb.this.dns_name
}

check "https_certificate" {
  assert {
    condition     = !var.enable_https || var.certificate_arn != null
    error_message = "enable_https = true requires certificate_arn."
  }
}

resource "aws_lb" "this" {
  name               = local.lb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnet_ids

  idle_timeout                     = 60
  drop_invalid_header_fields       = true
  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = true

  dynamic "access_logs" {
    for_each = var.access_logs_bucket == null ? [] : [1]
    content {
      bucket  = var.access_logs_bucket
      prefix  = local.lb_name
      enabled = true
    }
  }

  tags = merge(var.tags, {
    Name = local.lb_name
  })
}

resource "aws_lb_target_group" "this" {
  name        = local.tg_name
  port        = var.target_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200-299"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = merge(var.tags, {
    Name = local.tg_name
  })
}

###############################################################################
# Listeners
###############################################################################

# HTTP only, no certificate configured.
resource "aws_lb_listener" "http" {
  count = var.enable_https ? 0 : 1

  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# HTTP -> HTTPS redirect once a certificate is configured.
resource "aws_lb_listener" "http_redirect" {
  count = var.enable_https ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  count = var.enable_https ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

###############################################################################
# Optional DNS alias
###############################################################################

resource "aws_route53_record" "app" {
  count = var.route53_zone_id == null || var.domain_name == null ? 0 : 1

  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}
