# CloudWatch Log Groups para Lambda Functions
resource "aws_cloudwatch_log_group" "lambda_reclamos_logs" {
  name              = "/aws/lambda/${local.project_name}-lambda-reclamos"
  retention_in_days = 14

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "lambda_procesamiento_logs" {
  name              = "/aws/lambda/${local.project_name}-lambda-procesamiento"
  retention_in_days = 14

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "lambda_reportes_logs" {
  name              = "/aws/lambda/${local.project_name}-lambda-reportes"
  retention_in_days = 14

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "lambda_control_plazos_logs" {
  name              = "/aws/lambda/${local.project_name}-lambda-control-plazos"
  retention_in_days = 14

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "lambda_notificaciones_logs" {
  name              = "/aws/lambda/${local.project_name}-lambda-notificaciones"
  retention_in_days = 14

  tags = local.common_tags
}

# CloudWatch Log Group para API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${local.project_name}"
  retention_in_days = 14

  tags = local.common_tags
}

# CloudWatch Alarms para Lambda Functions

# Alarm para errores en Lambda Reclamos
resource "aws_cloudwatch_metric_alarm" "lambda_reclamos_errors" {
  alarm_name          = "${local.project_name}-lambda-reclamos-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Lambda Reclamos error rate"
  alarm_actions       = [aws_sns_topic.urgent_notifications.arn]

  dimensions = {
    FunctionName = "${local.project_name}-lambda-reclamos"
  }

  tags = local.common_tags
}

# Alarm para duración en Lambda Reclamos
resource "aws_cloudwatch_metric_alarm" "lambda_reclamos_duration" {
  alarm_name          = "${local.project_name}-lambda-reclamos-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "10000" # 10 seconds
  alarm_description   = "Lambda Reclamos duration is too high"
  alarm_actions       = [aws_sns_topic.urgent_notifications.arn]

  dimensions = {
    FunctionName = "${local.project_name}-lambda-reclamos"
  }

  tags = local.common_tags
}

# Alarm para errores en Lambda Procesamiento
resource "aws_cloudwatch_metric_alarm" "lambda_procesamiento_errors" {
  alarm_name          = "${local.project_name}-lambda-procesamiento-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "3"
  alarm_description   = "Lambda Procesamiento error rate"
  alarm_actions       = [aws_sns_topic.urgent_notifications.arn]

  dimensions = {
    FunctionName = "${local.project_name}-lambda-procesamiento"
  }

  tags = local.common_tags
}

# Alarm para DynamoDB throttles
resource "aws_cloudwatch_metric_alarm" "dynamodb_throttles" {
  alarm_name          = "${local.project_name}-dynamodb-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "DynamoDB throttling detected"
  alarm_actions       = [aws_sns_topic.urgent_notifications.arn]

  dimensions = {
    TableName = aws_dynamodb_table.reclamos.name
  }

  tags = local.common_tags
}

# Alarm para API Gateway 4XX errors
resource "aws_cloudwatch_metric_alarm" "api_gateway_4xx_errors" {
  alarm_name          = "${local.project_name}-api-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "API Gateway 4XX error rate is high"
  alarm_actions       = [aws_sns_topic.urgent_notifications.arn]

  tags = local.common_tags
}

# Alarm para API Gateway 5XX errors
resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx_errors" {
  alarm_name          = "${local.project_name}-api-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "API Gateway 5XX error detected"
  alarm_actions       = [aws_sns_topic.urgent_notifications.arn]

  tags = local.common_tags
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "${local.project_name}-lambda-reclamos"],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Lambda Reclamos Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", aws_dynamodb_table.reclamos.name],
            [".", "ConsumedWriteCapacityUnits", ".", "."],
            [".", "ThrottledRequests", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "DynamoDB Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiName", "${local.project_name}-api"],
            [".", "Latency", ".", "."],
            [".", "4XXError", ".", "."],
            [".", "5XXError", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "API Gateway Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/SNS", "NumberOfMessagesPublished", "TopicName", aws_sns_topic.reclamos_notifications.name],
            [".", "NumberOfNotificationsFailed", ".", "."],
            [".", "NumberOfNotificationsDelivered", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "SNS Notifications Metrics"
          period  = 300
        }
      }
    ]
  })
}

# CloudWatch Event Rule para Lambda Control Plazos (Cron diario)
resource "aws_cloudwatch_event_rule" "control_plazos_schedule" {
  name                = "${local.project_name}-control-plazos-schedule"
  description         = "Trigger Lambda Control Plazos daily at 8 AM"
  schedule_expression = "cron(0 8 * * ? *)" # Diario a las 8:00 AM UTC

  tags = local.common_tags
}

# CloudWatch Event Target para Lambda Control Plazos
resource "aws_cloudwatch_event_target" "lambda_control_plazos_target" {
  rule      = aws_cloudwatch_event_rule.control_plazos_schedule.name
  target_id = "LambdaControlPlazosTarget"
  arn       = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${local.project_name}-lambda-control-plazos"
}

# Permission para EventBridge invocar Lambda
resource "aws_lambda_permission" "allow_eventbridge_control_plazos" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = "${local.project_name}-lambda-control-plazos"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.control_plazos_schedule.arn
}

# CloudWatch Insights Queries predefinidas
resource "aws_cloudwatch_query_definition" "lambda_errors" {
  name = "${local.project_name}/lambda-errors"

  log_group_names = [
    aws_cloudwatch_log_group.lambda_reclamos_logs.name,
    aws_cloudwatch_log_group.lambda_procesamiento_logs.name,
    aws_cloudwatch_log_group.lambda_reportes_logs.name,
    aws_cloudwatch_log_group.lambda_control_plazos_logs.name,
    aws_cloudwatch_log_group.lambda_notificaciones_logs.name
  ]

  query_string = <<EOF
fields @timestamp, @message, @logStream
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
EOF
}

resource "aws_cloudwatch_query_definition" "api_gateway_slow_requests" {
  name = "${local.project_name}/api-slow-requests"

  log_group_names = [
    aws_cloudwatch_log_group.api_gateway_logs.name
  ]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /responseTime/
| filter responseTime > 1000
| sort @timestamp desc
| limit 50
EOF
}