# IAM Role para Lambda Reclamos
resource "aws_iam_role" "lambda_reclamos_role" {
  name = "${local.project_name}-lambda-reclamos-role"

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

# IAM Policy para Lambda Reclamos
resource "aws_iam_role_policy" "lambda_reclamos_policy" {
  name = "${local.project_name}-lambda-reclamos-policy"
  role = aws_iam_role.lambda_reclamos_role.id

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
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.reclamos.arn,
          "${aws_dynamodb_table.reclamos.arn}/index/*",
          aws_dynamodb_table.ciudadanos.arn,
          "${aws_dynamodb_table.ciudadanos.arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [
          aws_sns_topic.reclamos_notifications.arn
        ]
      }
    ]
  })
}

# IAM Role para Lambda Procesamiento
resource "aws_iam_role" "lambda_procesamiento_role" {
  name = "${local.project_name}-lambda-procesamiento-role"

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

# IAM Policy para Lambda Procesamiento
resource "aws_iam_role_policy" "lambda_procesamiento_policy" {
  name = "${local.project_name}-lambda-procesamiento-policy"
  role = aws_iam_role.lambda_procesamiento_role.id

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
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.reclamos.arn,
          "${aws_dynamodb_table.reclamos.arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.api_keys.arn,
          aws_secretsmanager_secret.security_config.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [
          aws_sns_topic.reclamos_notifications.arn
        ]
      }
    ]
  })
}

# IAM Role para Lambda Reportes
resource "aws_iam_role" "lambda_reportes_role" {
  name = "${local.project_name}-lambda-reportes-role"

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

# IAM Policy para Lambda Reportes
resource "aws_iam_role_policy" "lambda_reportes_policy" {
  name = "${local.project_name}-lambda-reportes-policy"
  role = aws_iam_role.lambda_reportes_role.id

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
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:GetItem",
          "dynamodb:PutItem"
        ]
        Resource = [
          aws_dynamodb_table.reclamos.arn,
          "${aws_dynamodb_table.reclamos.arn}/index/*",
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
          aws_sns_topic.reportes_notifications.arn
        ]
      }
    ]
  })
}

# IAM Role para Lambda Control Plazos
resource "aws_iam_role" "lambda_control_plazos_role" {
  name = "${local.project_name}-lambda-control-plazos-role"

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

# IAM Policy para Lambda Control Plazos
resource "aws_iam_role_policy" "lambda_control_plazos_policy" {
  name = "${local.project_name}-lambda-control-plazos-policy"
  role = aws_iam_role.lambda_control_plazos_role.id

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
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.reclamos.arn,
          "${aws_dynamodb_table.reclamos.arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [
          aws_sns_topic.control_plazos_alerts.arn,
          aws_sns_topic.urgent_notifications.arn
        ]
      }
    ]
  })
}

# IAM Role para Lambda Notificaciones
resource "aws_iam_role" "lambda_notificaciones_role" {
  name = "${local.project_name}-lambda-notificaciones-role"

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

# IAM Policy para Lambda Notificaciones
resource "aws_iam_role_policy" "lambda_notificaciones_policy" {
  name = "${local.project_name}-lambda-notificaciones-policy"
  role = aws_iam_role.lambda_notificaciones_role.id

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
          "ses:SendEmail",
          "ses:SendRawEmail",
          "ses:SendTemplatedEmail"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.email_config.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.ciudadanos.arn,
          "${aws_dynamodb_table.ciudadanos.arn}/index/*",
          aws_dynamodb_table.funcionarios.arn,
          "${aws_dynamodb_table.funcionarios.arn}/index/*"
        ]
      }
    ]
  })
}

# IAM Role para API Gateway
resource "aws_iam_role" "api_gateway_role" {
  name = "${local.project_name}-api-gateway-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM Policy para API Gateway CloudWatch Logs
resource "aws_iam_role_policy" "api_gateway_logs_policy" {
  name = "${local.project_name}-api-gateway-logs-policy"
  role = aws_iam_role.api_gateway_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Roles para Cognito Identity Pool
resource "aws_iam_role" "authenticated_role" {
  name = "${local.project_name}-cognito-authenticated-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

# Policy para usuarios autenticados
resource "aws_iam_role_policy" "authenticated_policy" {
  name = "${local.project_name}-cognito-authenticated-policy"
  role = aws_iam_role.authenticated_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "execute-api:Invoke"
        ]
        Resource = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}://GET/*",
        Resource = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}://POST/*",
        Resource = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}://PUT/*"
      }
    ]
  })
}

# Attachment de roles a Identity Pool
resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.main.id

  roles = {
    "authenticated" = aws_iam_role.authenticated_role.arn
  }
}