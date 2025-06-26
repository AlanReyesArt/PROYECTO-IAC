# Dead-Letter Queue (DLQ) para mensajes fallidos
resource "aws_sqs_queue" "procesamiento_dlq" {
  name                      = "${local.project_name}-procesamiento-dlq"
  message_retention_seconds = 1209600 # 14 días
  kms_master_key_id         = "alias/aws/sqs"

  tags = local.common_tags
}

# Cola principal para procesamiento asíncrono de reclamos
resource "aws_sqs_queue" "procesamiento_queue" {
  name                        = "${local.project_name}-procesamiento-queue"
  delay_seconds               = 0
  max_message_size            = 262144 # 256 KiB
  message_retention_seconds   = 345600 # 4 días
  receive_wait_time_seconds   = 10     # Habilita long polling
  visibility_timeout_seconds  = 120    # Debe ser >= al timeout de la lambda de procesamiento (60s)
  kms_master_key_id           = "alias/aws/sqs"

  # Redrive policy para enviar mensajes fallidos a la DLQ
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.procesamiento_dlq.arn
    maxReceiveCount     = 3 # Intentar procesar un mensaje 3 veces antes de enviarlo a la DLQ
  })

  tags = local.common_tags
}