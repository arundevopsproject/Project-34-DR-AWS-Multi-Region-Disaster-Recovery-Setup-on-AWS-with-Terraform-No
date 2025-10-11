locals {
  common_tags = {
    ManagedBy = "terraform"
  }
}

# Route 53 Hosted Zone
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = local.common_tags
}

# Health check for primary region
resource "aws_route53_health_check" "primary" {
  fqdn                            = var.primary_alb_dns_name
  port                            = 80
  type                            = "HTTP"
  resource_path                   = var.health_check_path
  failure_threshold               = 3
  request_interval                = 30
  cloudwatch_alarm_region         = "us-east-1"
  cloudwatch_alarm_name           = "primary-health-check"
  insufficient_data_health_status = "Failure"

  tags = merge(local.common_tags, {
    Name = "Primary Region Health Check"
  })
}

# Primary record (active)
resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  set_identifier = "primary"
  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.primary.id

  alias {
    name                   = var.primary_alb_dns_name
    zone_id                = var.primary_alb_zone_id
    evaluate_target_health = true
  }
}

# Secondary record (standby)
resource "aws_route53_record" "secondary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  set_identifier = "secondary"
  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = var.dr_alb_dns_name
    zone_id                = var.dr_alb_zone_id
    evaluate_target_health = true
  }
}

# CloudWatch alarm for health check
resource "aws_cloudwatch_metric_alarm" "primary_health_check" {
  alarm_name          = "primary-health-check"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "This metric monitors the health check status"
  treat_missing_data  = "breaching"

  dimensions = {
    HealthCheckId = aws_route53_health_check.primary.id
  }

  tags = local.common_tags
}

# Additional health check records for monitoring
resource "aws_route53_record" "health_check" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "health.${var.domain_name}"
  type    = "A"
  ttl     = 60
  records = ["127.0.0.1"]
}

# WWW redirect
resource "aws_route53_record" "www_primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  set_identifier = "www-primary"
  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.primary.id

  alias {
    name                   = var.primary_alb_dns_name
    zone_id                = var.primary_alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www_secondary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  set_identifier = "www-secondary"
  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = var.dr_alb_dns_name
    zone_id                = var.dr_alb_zone_id
    evaluate_target_health = true
  }
}