# IAM Role para Lambda Functions
resource "aws_iam_role" "lambda_role" {
  name = "${local.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM Policy para Lambda Functions
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${local.project_name}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:::*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.reclamos.arn,
          "${aws_dynamodb_table.reclamos.arn}/index/*",
          aws_dynamodb_table.ciudadanos.arn,
          "${aws_dynamodb_table.ciudadanos.arn}/index/*",
          aws_dynamodb_table.funcionarios.arn,
          "${aws_dynamodb_table.funcionarios.arn}/index/*",
          aws_dynamodb_table.reportes.arn,
          "${aws_dynamodb_table.reportes.arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [
          aws_sns_topic.reclamos_notifications.arn,
          aws_sns_topic.control_plazos_alerts.arn,
          aws_sns_topic.reportes_notifications.arn,
          aws_sns_topic.urgent_notifications.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendTemplatedEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      },
    ]
  })
}

# Lambda Function: Reclamos (CRUD Operations)
resource "aws_lambda_function" "lambda_reclamos" {
  filename         = "lambda_reclamos.zip"
  function_name    = "${local.project_name}-reclamos"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 30

  environment {
    variables = {
      DYNAMODB_TABLE_RECLAMOS    = aws_dynamodb_table.reclamos.name
      DYNAMODB_TABLE_CIUDADANOS  = aws_dynamodb_table.ciudadanos.name
      DYNAMODB_TABLE_FUNCIONARIOS = aws_dynamodb_table.funcionarios.name
      SNS_TOPIC_NOTIFICATIONS    = aws_sns_topic.reclamos_notifications.arn
      SQS_QUEUE_URL = aws_sqs_queue.procesamiento_queue.url
    }
  }

  tags = local.common_tags

  # Placeholder file creation
  depends_on = [aws_iam_role_policy.lambda_policy]
}

# Lambda Function: Procesamiento
resource "aws_lambda_function" "lambda_procesamiento" {
  filename         = "lambda_procesamiento.zip"
  function_name    = "${local.project_name}-procesamiento"
  role            = aws_iam_role.lambda_procesamiento_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 60

  environment {
    variables = {
      DYNAMODB_TABLE_RECLAMOS = aws_dynamodb_table.reclamos.name
      SNS_TOPIC_NOTIFICATIONS = aws_sns_topic.reclamos_notifications.arn
    }
  }

  tags = local.common_tags

  depends_on = [aws_iam_role_policy.lambda_policy]
}

# Lambda Function: Reportes
resource "aws_lambda_function" "lambda_reportes" {
  filename         = "lambda_reportes.zip"
  function_name    = "${local.project_name}-reportes"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 60

  environment {
    variables = {
      DYNAMODB_TABLE_RECLAMOS = aws_dynamodb_table.reclamos.name
      DYNAMODB_TABLE_REPORTES = aws_dynamodb_table.reportes.name
      SNS_TOPIC_REPORTES     = aws_sns_topic.reportes_notifications.arn
    }
  }

  tags = local.common_tags

  depends_on = [aws_iam_role_policy.lambda_policy]
}

# Lambda Function: Control de Plazos
resource "aws_lambda_function" "lambda_control_plazos" {
  filename         = "lambda_control_plazos.zip"
  function_name    = "${local.project_name}-control-plazos"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  environment {
    variables = {
      DYNAMODB_TABLE_RECLAMOS = aws_dynamodb_table.reclamos.name
      SNS_TOPIC_ALERTS       = aws_sns_topic.control_plazos_alerts.arn
      SNS_TOPIC_URGENT       = aws_sns_topic.urgent_notifications.arn
    }
  }

  tags = local.common_tags

  depends_on = [aws_iam_role_policy.lambda_policy]
}

# Lambda Function: Notificaciones
resource "aws_lambda_function" "lambda_notificaciones" {
  filename         = "lambda_notificaciones.zip"
  function_name    = "${local.project_name}-notificaciones"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 30

  environment {
    variables = {
      DYNAMODB_TABLE_CIUDADANOS  = aws_dynamodb_table.ciudadanos.name
      DYNAMODB_TABLE_FUNCIONARIOS = aws_dynamodb_table.funcionarios.name
      SES_CONFIG_SET            = aws_ses_configuration_set.main.name
      FROM_EMAIL                = var.notification_email
    }
  }

  tags = local.common_tags

  depends_on = [aws_iam_role_policy.lambda_policy]
}

# SNS Subscription para Lambda Notificaciones
resource "aws_sns_topic_subscription" "lambda_notificaciones_reclamos" {
  topic_arn = aws_sns_topic.reclamos_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda_notificaciones.arn
}

resource "aws_sns_topic_subscription" "lambda_notificaciones_plazos" {
  topic_arn = aws_sns_topic.control_plazos_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda_notificaciones.arn
}

resource "aws_sns_topic_subscription" "lambda_notificaciones_reportes" {
  topic_arn = aws_sns_topic.reportes_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda_notificaciones.arn
}

# Permisos para que SNS pueda invocar Lambda
resource "aws_lambda_permission" "sns_invoke_notifications_reclamos" {
  statement_id  = "AllowExecutionFromSNSReclamos"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_notificaciones.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.reclamos_notifications.arn
}

resource "aws_lambda_permission" "sns_invoke_notifications_plazos" {
  statement_id  = "AllowExecutionFromSNSPlazos"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_notificaciones.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.control_plazos_alerts.arn
}

resource "aws_lambda_permission" "sns_invoke_notifications_reportes" {
  statement_id  = "AllowExecutionFromSNSReportes"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_notificaciones.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.reportes_notifications.arn
}

# Permiso para que API Gateway invoque lambda_reclamos
resource "aws_lambda_permission" "api_gateway_invoke_reclamos" {
  statement_id  = "AllowExecutionFromAPIGatewayReclamos"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_reclamos.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# Permiso para que API Gateway invoque lambda_reportes
resource "aws_lambda_permission" "api_gateway_invoke_reportes" {
  statement_id  = "AllowExecutionFromAPIGatewayReportes"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_reportes.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_event_source_mapping" "procesamiento_trigger" {
  event_source_arn = aws_sqs_queue.procesamiento_queue.arn
  function_name    = aws_lambda_function.lambda_procesamiento.arn
  batch_size       = 5 # Cuántos mensajes procesar a la vez
  enabled          = true
}

# Placeholder para los archivos ZIP de las funciones Lambda
data "archive_file" "lambda_reclamos_zip" {
  type        = "zip"
  output_path = "lambda_reclamos.zip"
  source {
    content  = "def handler(event, context): return {'statusCode': 200, 'body': 'Lambda Reclamos'}"
    filename = "index.py"
  }
}

data "archive_file" "lambda_procesamiento_zip" {
  type        = "zip"
  output_path = "lambda_procesamiento.zip"
  source {
    content  = "def handler(event, context): return {'statusCode': 200, 'body': 'Lambda Procesamiento'}"
    filename = "index.py"
  }
}

data "archive_file" "lambda_reportes_zip" {
  type        = "zip"
  output_path = "lambda_reportes.zip"
  source {
    content  = "def handler(event, context): return {'statusCode': 200, 'body': 'Lambda Reportes'}"
    filename = "index.py"
  }
}

data "archive_file" "lambda_control_plazos_zip" {
  type        = "zip"
  output_path = "lambda_control_plazos.zip"
  source {
    content  = "def handler(event, context): return {'statusCode': 200, 'body': 'Lambda Control Plazos'}"
    filename = "index.py"
  }
}

data "archive_file" "lambda_notificaciones_zip" {
  type        = "zip"
  output_path = "lambda_notificaciones.zip"
  source {
    content  = "def handler(event, context): return {'statusCode': 200, 'body': 'Lambda Notificaciones'}"
    filename = "index.py"
  }
}