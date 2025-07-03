import json
import os
import uuid
import boto3
import logging
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """
    Maneja la creación de nuevos reclamos a través de una petición POST de API Gateway.
    """
    logger.info(f"## EVENTO RECIBIDO:\n{json.dumps(event)}")
    
    # --- INICIO DE LA CORRECCIÓN ---
    # Inicializamos los clientes y recursos DENTRO del handler.
    # Esto asegura que en las pruebas, se usan los recursos simulados por 'moto'.
    try:
        DYNAMODB_TABLE = os.environ['DYNAMODB_TABLE_RECLAMOS']
        SQS_QUEUE_URL = os.environ['SQS_QUEUE_URL']
        
        dynamodb_resource = boto3.resource('dynamodb')
        sqs_client = boto3.client('sqs')
        
        table = dynamodb_resource.Table(DYNAMODB_TABLE)
    except KeyError as e:
        logger.error(f"Error de configuración: Falta la variable de entorno {e}")
        return {'statusCode': 500, 'body': json.dumps({'message': 'Error de configuración del servidor'})}
    # --- FIN DE LA CORRECCIÓN ---

    try:
        http_method = event['requestContext']['http']['method']
        if http_method != 'POST':
            return {'statusCode': 405, 'body': json.dumps({'message': 'Método no permitido'})}
        
        data = json.loads(event.get('body', '{}'))
    except (KeyError, json.JSONDecodeError):
        return {'statusCode': 400, 'body': json.dumps({'message': 'Cuerpo de la petición inválido o ausente'})}

    required_fields = ['descripcion', 'ciudadanoId']
    if not all(field in data for field in required_fields):
        return {'statusCode': 400, 'body': json.dumps({'message': 'Faltan los campos requeridos: descripcion y ciudadanoId'})}

    try:
        reclamo_id = str(uuid.uuid4())
        item = {
            'reclamoId': reclamo_id,
            'descripcion': data['descripcion'],
            'ciudadanoId': data['ciudadanoId'],
            'estado': 'PENDIENTE',
            'fechaCreacion': datetime.utcnow().isoformat()
        }
        
        table.put_item(Item=item)
        logger.info(f"Reclamo {reclamo_id} guardado en DynamoDB.")
        
        sqs_client.send_message(
            QueueUrl=SQS_QUEUE_URL,
            MessageBody=json.dumps({'reclamoId': reclamo_id})
        )
        logger.info(f"Mensaje para el reclamo {reclamo_id} enviado a SQS.")

        return {
            'statusCode': 201,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'message': 'Reclamo creado exitosamente',
                'reclamoId': reclamo_id
            })
        }
    except Exception as e:
        logger.error(f"Error al procesar el reclamo: {e}")
        return {'statusCode': 500, 'body': json.dumps({'message': 'Error interno del servidor'})}