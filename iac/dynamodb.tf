# DynamoDB Table para Reclamos
resource "aws_dynamodb_table" "reclamos" {
  name           = "${local.project_name}-reclamos"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "reclamoId"
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "reclamoId"
    type = "S"
  }

  attribute {
    name = "ciudadanoId"
    type = "S"
  }

  attribute {
    name = "estado"
    type = "S"
  }

  attribute {
    name = "fechaCreacion"
    type = "S"
  }

  attribute {
    name = "fechaVencimiento"
    type = "S"
  }

  attribute {
    name = "tipo"
    type = "S"
  }

  attribute {
    name = "prioridad"
    type = "S"
  }

  # GSI1: Consultas por ciudadano
  global_secondary_index {
    name     = "GSI1"
    hash_key = "ciudadanoId"
    range_key = "fechaCreacion"
    projection_type = "ALL"
  }

  # GSI2: Consultas por estado y vencimiento
  global_secondary_index {
    name     = "GSI2"
    hash_key = "estado"
    range_key = "fechaVencimiento"
    projection_type = "ALL"
  }

  # GSI3: Consultas por tipo y prioridad
  global_secondary_index {
    name     = "GSI3"
    hash_key = "tipo"
    range_key = "prioridad"
    projection_type = "ALL"
  }

  # Configuración de punto de recuperación
  point_in_time_recovery {
    enabled = true
  }

  # Configuración de encriptación
  server_side_encryption {
    enabled = true
  }

  tags = local.common_tags
}

# DynamoDB Table para Usuarios/Ciudadanos
resource "aws_dynamodb_table" "ciudadanos" {
  name         = "${local.project_name}-ciudadanos"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ciudadanoId"

  attribute {
    name = "ciudadanoId"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  # GSI para búsqueda por email
  global_secondary_index {
    name     = "EmailIndex"
    hash_key = "email"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = local.common_tags
}

# DynamoDB Table para Funcionarios
resource "aws_dynamodb_table" "funcionarios" {
  name         = "${local.project_name}-funcionarios"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "funcionarioId"

  attribute {
    name = "funcionarioId"
    type = "S"
  }

  attribute {
    name = "departamento"
    type = "S"
  }

  attribute {
    name = "especialidad"
    type = "S"
  }

  # GSI para búsqueda por departamento
  global_secondary_index {
    name     = "DepartamentoIndex"
    hash_key = "departamento"
    range_key = "especialidad"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = local.common_tags
}

# DynamoDB Table para Reportes y Métricas
resource "aws_dynamodb_table" "reportes" {
  name         = "${local.project_name}-reportes"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "reporteId"
  range_key    = "fecha"

  attribute {
    name = "reporteId"
    type = "S"
  }

  attribute {
    name = "fecha"
    type = "S"
  }

  attribute {
    name = "tipo"
    type = "S"
  }

  # GSI para consultas por tipo de reporte
  global_secondary_index {
    name     = "TipoIndex"
    hash_key = "tipo"
    range_key = "fecha"
    projection_type = "ALL"
  }

  # TTL para limpieza automática de reportes antiguos
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = local.common_tags
}