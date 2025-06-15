# SNS Topic para notificaciones de reclamos
resource "aws_sns_topic" "reclamos_notifications" {
  name = "${local.project_name}-reclamos-notifications"
  kms_master_key_id = "alias/aws/sns"
  tags = local.common_tags
}

# SNS Topic para alertas de control de plazos
resource "aws_sns_topic" "control_plazos_alerts" {
  name = "${local.project_name}-control-plazos-alerts"
  kms_master_key_id = "alias/aws/sns"
  tags = local.common_tags
}

# SNS Topic para reportes
resource "aws_sns_topic" "reportes_notifications" {
  name = "${local.project_name}-reportes-notifications"
  kms_master_key_id = "alias/aws/sns"
  tags = local.common_tags
}

# SNS Topic para notificaciones urgentes
resource "aws_sns_topic" "urgent_notifications" {
  name = "${local.project_name}-urgent-notifications"
  kms_master_key_id = "alias/aws/sns"
  tags = local.common_tags
}

# Suscripción de email para notificaciones administrativas
resource "aws_sns_topic_subscription" "admin_email" {
  topic_arn = aws_sns_topic.urgent_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# Política para permitir que las Lambda functions publiquen en SNS
resource "aws_sns_topic_policy" "reclamos_notifications_policy" {
  arn = aws_sns_topic.reclamos_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.reclamos_notifications.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic_policy" "control_plazos_policy" {
  arn = aws_sns_topic.control_plazos_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.control_plazos_alerts.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic_policy" "reportes_policy" {
  arn = aws_sns_topic.reportes_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.reportes_notifications.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic_policy" "urgent_notifications_policy" {
  arn = aws_sns_topic.urgent_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.urgent_notifications.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# Data source para obtener información de la cuenta actual
data "aws_caller_identity" "current" {}