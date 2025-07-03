import unittest
import os
import json
from unittest.mock import patch
from moto import mock_aws

# Debemos definir las variables de entorno ANTES de importar la app
# para que los clientes de boto3 se inicialicen correctamente
os.environ['DYNAMODB_TABLE_RECLAMOS'] = 'tabla-test-reclamos'

# Importamos el handler después de mockear las variables de entorno
from src.lambda_reclamos.app import handler

# Usamos el decorador @mock_aws para simular los servicios de AWS
@mock_aws
class TestLambdaReclamos(unittest.TestCase):

    def setUp(self):
    """
    Este método se ejecuta ANTES de cada prueba.
    Crea los recursos de AWS simulados (mock) que necesitamos.
    """
    import boto3
    # Usaremos us-east-1 para todo para mantener consistencia
    aws_region = 'us-east-2'

    # --- Setup SQS (lo hacemos primero) ---
    sqs = boto3.client('sqs', region_name=aws_region)
    # Creamos la cola simulada
    queue_name = 'cola-test'
    response = sqs.create_queue(QueueName=queue_name)
    
    # Obtenemos la URL REAL de la cola simulada y la ponemos en la variable de entorno
    # para que la app la pueda usar.
    os.environ['SQS_QUEUE_URL'] = response['QueueUrl']

    # --- Setup DynamoDB ---
    dynamodb = boto3.resource('dynamodb', region_name=aws_region)
    table_name = 'tabla-test-reclamos'
    dynamodb.create_table(
        TableName=table_name,
        KeySchema=[{'AttributeName': 'reclamoId', 'KeyType': 'HASH'}],
        AttributeDefinitions=[{'AttributeName': 'reclamoId', 'AttributeType': 'S'}],
        ProvisionedThroughput={'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1}
    )
    self.dynamodb_table = dynamodb.Table(table_name)

    def test_crear_reclamo_exitoso(self):
        """
        Prueba el caso de éxito: crear un reclamo con datos válidos.
        """
        # 1. PREPARACIÓN: Creamos el evento que simula una llamada de API Gateway
        test_event = {
            "requestContext": {"http": {"method": "POST"}},
            "body": json.dumps({
                "descripcion": "Poste de luz roto en la plaza principal.",
                "ciudadanoId": "ciudadano-007"
            })
        }

        # 2. EJECUCIÓN: Llamamos a nuestro handler de Lambda
        response = handler(test_event, {})
        
        # 3. VERIFICACIÓN (Asserts)
        # Verificamos que la respuesta HTTP sea la correcta (201 Created)
        self.assertEqual(response['statusCode'], 201)
        
        # Verificamos que el cuerpo de la respuesta contenga el ID del reclamo
        response_body = json.loads(response['body'])
        self.assertIn('reclamoId', response_body)
        
        # Verificamos que el reclamo se haya guardado en nuestra tabla simulada de DynamoDB
        reclamo_id = response_body['reclamoId']
        db_item = self.dynamodb_table.get_item(Key={'reclamoId': reclamo_id}).get('Item')
        
        self.assertIsNotNone(db_item)
        self.assertEqual(db_item['ciudadanoId'], 'ciudadano-007')
        self.assertEqual(db_item['estado'], 'PENDIENTE')

    def test_crear_reclamo_con_datos_faltantes(self):
        """
        Prueba el caso de error: intentar crear un reclamo sin todos los datos.
        """
        # 1. PREPARACIÓN: Evento con datos incompletos
        test_event = {
            "requestContext": {"http": {"method": "POST"}},
            "body": json.dumps({
                "descripcion": "Datos incompletos"
                # Falta ciudadanoId
            })
        }
        
        # 2. EJECUCIÓN:
        response = handler(test_event, {})
        
        # 3. VERIFICACIÓN:
        # Verificamos que la respuesta sea un error 400 (Bad Request)
        self.assertEqual(response['statusCode'], 400)
        self.assertIn('Faltan los campos', response['body'])

if __name__ == '___main__':
    unittest.main()