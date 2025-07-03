import json
import os
import uuid
import boto3
import logging
from datetime import datetime

# --- Configuración Inicial ---
# Es una buena práctica inicializar los clientes de AWS fuera del handler
# para reutilizar las conexiones y mejorar el rendimiento.
logger = logging.getLogger()
logger.setLevel(logging.INFO)

try:
    DYNAMODB_TABLE = os.environ['DYNAMODB_TABLE_RECLAMOS']
    SQS_QUEUE_URL = os.environ['SQS_QUEUE_URL']
    
    dynamodb_resource = boto3.resource('dynamodb')
    sqs_client = boto3.client('sqs')
    
    table = dynamodb_resource.Table(DYNAMODB_TABLE)
except KeyError as e:
    logger.error(f"Error: La variable de entorno {e} no está definida.")
    # Si falta una variable de entorno, la Lambda no podrá funcionar.
    # Es mejor fallar rápido en la inicialización.
    raise

def handler(event, context):
    """
    Maneja la creación de nuevos reclamos a través de una petición POST de API Gateway.
    """
    logger.info(f"## EVENTO RECIBIDO:\n{json.dumps(event)}")

    # 1. Validar que el método sea POST
    try:
        http_method = event['requestContext']['http']['method']
        if http_method != 'POST':
            return {
                'statusCode': 405,
                'body': json.dumps({'message': 'Método no permitido'})
            }
        
        data = json.loads(event.get('body', '{}'))
    except (KeyError, json.JSONDecodeError):
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'Cuerpo de la petición inválido o ausente'})
        }

    # 2. Validar campos requeridos (basado en tu prueba 'test_crear_reclamo_con_datos_faltantes')
    required_fields = ['descripcion', 'ciudadanoId']
    if not all(field in data for field in required_fields):
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'Faltan los campos requeridos: descripcion y ciudadanoId'})
        }

    # 3. Procesar el reclamo (basado en tu prueba 'test_crear_reclamo_exitoso')
    try:
        reclamo_id = str(uuid.uuid4())
        
        # Crear el item para DynamoDB
        item = {
            'reclamoId': reclamo_id,
            'descripcion': data['descripcion'],
            'ciudadanoId': data['ciudadanoId'],
            'estado': 'PENDIENTE',
            'fechaCreacion': datetime.utcnow().isoformat()
        }
        
        # Guardar en DynamoDB
        table.put_item(Item=item)
        logger.info(f"Reclamo {reclamo_id} guardado en DynamoDB.")
        
        # Enviar mensaje a SQS para procesamiento asíncrono
        sqs_client.send_message(
            QueueUrl=SQS_QUEUE_URL,
            MessageBody=json.dumps({'reclamoId': reclamo_id})
        )
        logger.info(f"Mensaje para el reclamo {reclamo_id} enviado a SQS.")

        # 4. Devolver respuesta exitosa
        return {
            'statusCode': 201, # 201 Created es más apropiado para un POST exitoso
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'message': 'Reclamo creado exitosamente',
                'reclamoId': reclamo_id
            })
        }
        
    except Exception as e:
        logger.error(f"Error al procesar el reclamo: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Error interno del servidor'})
        }