# Secrets Manager para configuraciones sensibles
resource "aws_secretsmanager_secret" "api_keys" {
  name                    = "${local.project_name}/api-keys"
  description             = "API keys for external services"
  recovery_window_in_days = 7

  tags = local.common_tags
}

# Valores por defecto para las API keys (deben ser actualizados manualmente)
resource "aws_secretsmanager_secret_version" "api_keys" {
  secret_id = aws_secretsmanager_secret.api_keys.id
  secret_string = jsonencode({
    geolocation_api_key = "your-geolocation-api-key-here"
    maps_api_key       = "your-maps-api-key-here"
    sms_api_key        = "your-sms-service-api-key-here"
    webhook_secret     = "your-webhook-secret-here"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Secrets Manager para configuración de base de datos externa (si aplica)
resource "aws_secretsmanager_secret" "database_config" {
  name                    = "${local.project_name}/database-config"
  description             = "External database configuration"
  recovery_window_in_days = 7

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "database_config" {
  secret_id = aws_secretsmanager_secret.database_config.id
  secret_string = jsonencode({
    external_db_host     = "localhost"
    external_db_port     = "5432"
    external_db_name     = "external_data"
    external_db_username = "readonly_user"
    external_db_password = "change-me-please"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Secrets Manager para configuración de email
resource "aws_secretsmanager_secret" "email_config" {
  name                    = "${local.project_name}/email-config"
  description             = "Email service configuration"
  recovery_window_in_days = 7

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "email_config" {
  secret_id = aws_secretsmanager_secret.email_config.id
  secret_string = jsonencode({
    smtp_host     = "email-smtp.us-east-1.amazonaws.com"
    smtp_port     = "587"
    smtp_username = "your-ses-smtp-username"
    smtp_password = "your-ses-smtp-password"
    from_email    = var.notification_email
    from_name     = "Plataforma de Reclamos Ciudadanos"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Secrets Manager para JWT y configuraciones de seguridad
resource "aws_secretsmanager_secret" "security_config" {
  name                    = "${local.project_name}/security-config"
  description             = "Security configuration including JWT secrets"
  recovery_window_in_days = 7

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "security_config" {
  secret_id = aws_secretsmanager_secret.security_config.id
  secret_string = jsonencode({
    jwt_secret          = "your-very-long-and-secure-jwt-secret-key-here"
    encryption_key      = "your-encryption-key-for-sensitive-data"
    api_rate_limit      = "1000"
    session_timeout     = "3600"
    max_file_size_mb    = "10"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}