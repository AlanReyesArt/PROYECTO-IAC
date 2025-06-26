resource "aws_wafv2_web_acl" "main" {
  provider    = aws.us_east_1
  name        = "${local.project_name}-web-acl"
  scope       = "CLOUDFRONT"
  description = "WAF para la plataforma de reclamos ciudadanos"

  default_action {
    allow {}
  }

  # Dejamos una sola regla simple para la prueba
  rule {
    name     = "RateLimitRule"
    priority = 1
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = 500
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.project_name}-RateLimit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.project_name}-WAF"
    sampled_requests_enabled   = true
  }

  tags = local.common_tags
}