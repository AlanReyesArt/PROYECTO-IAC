# Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "${local.project_name}-user-pool"

  # Configuración de políticas de contraseña
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  # Configuración de atributos  
  alias_attributes = ["email", "preferred_username"]

  # Configuración de verificación
  auto_verified_attributes = ["email"]

  # Configuración de recuperación de cuenta
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Configuración de políticas de usuario
  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }

  # Configuración de verificación de email
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Código de verificación - ${local.project_name}"
    email_message        = "Tu código de verificación es {####}"
  }

  # Configuración de esquema de atributos
  schema {
    attribute_data_type = "String"
    name               = "email"
    required           = true
    mutable            = true
  }

  schema {
    attribute_data_type = "String"
    name               = "name"
    required           = true
    mutable            = true
  }

  schema {
    attribute_data_type = "String"
    name               = "phone_number"
    required           = false
    mutable            = true
  }

  tags = local.common_tags
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "main" {
  name         = "${local.project_name}-client"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = false

  # Configuración de flujos de autenticación
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  # Configuración de tokens
  access_token_validity  = 1  # 1 hora
  id_token_validity     = 1  # 1 hora
  refresh_token_validity = 30 # 30 días

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  # URLs de callback (para desarrollo local y producción)
  callback_urls = [
   # "http://localhost:3000/callback" ,
    "https://reclamos-ciudadanos-dev.auth.us-east-2.amazoncognito.com/oauth2/idpresponse"
  ]

  logout_urls = [
   # "http://localhost:3000/logout" ,
    "https://reclamos-ciudadanos-dev.auth.us-east-2.amazoncognito.com/logout"
  ]

  # Configuración OAuth
  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["email", "openid", "profile"]
  allowed_oauth_flows_user_pool_client = true

  # Configuración de lectura y escritura de atributos
  read_attributes = [
    "email",
    "name",
    "phone_number",
    "email_verified"
  ]

  write_attributes = [
    "email",
    "name",
    "phone_number"
  ]
}

# Cognito User Pool Domain
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${local.project_name}-${var.environment}"
  user_pool_id = aws_cognito_user_pool.main.id
}

# Identity Pool para acceso a recursos AWS
resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "${local.project_name}_identity_pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.main.id
    provider_name           = aws_cognito_user_pool.main.endpoint
    server_side_token_check = false
  }

  tags = local.common_tags
}