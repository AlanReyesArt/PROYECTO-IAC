# SES Email Identity Verification
resource "aws_ses_email_identity" "notification_email" {
  email = var.notification_email
}

# SES Domain Identity (opcional, para usar un dominio propio)
#resource "aws_ses_domain_identity" "main" {
#  domain = var.domain_name
#}

# SES Domain DKIM
#resource "aws_ses_domain_dkim" "main" {
#  domain = aws_ses_domain_identity.main.domain
#}

# Route53 records para verificación DKIM
#resource "aws_route53_record" "dkim" {
#  count   = 3
#  zone_id = data.aws_route53_zone.main.zone_id
#  name    = "${aws_ses_domain_dkim.main.dkim_tokens[count.index]}._domainkey"
#  type    = "CNAME"
#  ttl     = 600
#  records = ["${aws_ses_domain_dkim.main.dkim_tokens[count.index]}.dkim.amazonses.com"]
#}

# SES Configuration Set para tracking
resource "aws_ses_configuration_set" "main" {
  name = "${local.project_name}-config-set"

  delivery_options {
    tls_policy = "Require"
  }

  reputation_metrics_enabled = true
}

# Event destination para CloudWatch
resource "aws_ses_event_destination" "cloudwatch" {
  name                   = "cloudwatch-destination"
  configuration_set_name = aws_ses_configuration_set.main.name
  enabled                = true
  matching_types = [
    "send",
    "reject",
    "bounce",
    "complaint",
    "delivery",
    "click",
    "open"
  ]

  cloudwatch_destination {
    default_value  = "default"
    dimension_name = "MessageTag"
    value_source   = "messageTag"
  }
}

# SES Template para confirmación de reclamo
#resource "aws_ses_template" "reclamo_confirmacion" {
#  name    = "${local.project_name}-reclamo-confirmacion"
#  subject = "Confirmación de Reclamo - {{reclamoId}}"
#  html    = file("${path.module}/templates/reclamo_confirmacion.html")
#  text    = file("${path.module}/templates/reclamo_confirmacion.txt")
#}

# SES Template para actualización de estado
#resource "aws_ses_template" "reclamo_actualizacion" {
#  name    = "${local.project_name}-reclamo-actualizacion"
#  subject = "Actualización de Reclamo - {{reclamoId}}"
#   html    = file("${path.module}/templates/reclamo_actualizacion.html")
#   text    = file("${path.module}/templates/reclamo_actualizacion.txt")
# }

# SES Template para alertas de vencimiento
# resource "aws_ses_template" "reclamo_alerta" {
#   name    = "${local.project_name}-reclamo-alerta"
#   subject = "Alerta: Reclamo próximo a vencer - {{reclamoId}}"
#   html    = file("${path.module}/templates/reclamo_alerta.html")
#   text    = file("${path.module}/templates/reclamo_alerta.txt") 
# }