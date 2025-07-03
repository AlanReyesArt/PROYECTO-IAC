import unittest
import os
import json
import sys
import boto3
from moto import mock_aws

# Agregamos el directorio 'src' al path para que Python encuentre los módulos
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# Ahora podemos importar el handler de forma segura
from src.lambda_reclamos.app import handler

@mock_aws
class TestLambdaReclamos(unittest.TestCase):

    def setUp(self):
        """
        Se ejecuta ANTES de cada prueba. Crea TODOS los recursos simulados.
        """
        # Definimos variables de entorno para las pruebas
        os.environ['DYNAMODB_TABLE_RECLAMOS'] = 'tabla-test-reclamos'
        
        # Setup SQS y obtenemos la URL simulada
        sqs = boto3.client('sqs', region_name='us-east-1')
        sqs_response = sqs.create_queue(QueueName='cola-test')
        os.environ['SQS_QUEUE_URL'] = sqs_response['QueueUrl']
        
        # Setup DynamoDB
        dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
        dynamodb.create_table(
            TableName=os.environ['DYNAMODB_TABLE_RECLAMOS'],
            KeySchema=[{'AttributeName': 'reclamoId', 'KeyType': 'HASH'}],
            AttributeDefinitions=[{'AttributeName': 'reclamoId', 'AttributeType': 'S'}],
            ProvisionedThroughput={'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1}
        )
        self.dynamodb_table = dynamodb.Table(os.environ['DYNAMODB_TABLE_RECLAMOS'])

    def test_crear_reclamo_exitoso(self):
        """Prueba el caso de éxito: crear un reclamo con datos válidos."""
        test_event = {
            "requestContext": {"http": {"method": "POST"}},
            "body": json.dumps({
                "descripcion": "Poste de luz roto.",
                "ciudadanoId": "ciudadano-007"
            })
        }
        response = handler(test_event, {})
        
        self.assertEqual(response['statusCode'], 201)
        response_body = json.loads(response['body'])
        self.assertIn('reclamoId', response_body)
        
        reclamo_id = response_body['reclamoId']
        db_item = self.dynamodb_table.get_item(Key={'reclamoId': reclamo_id}).get('Item')
        
        self.assertIsNotNone(db_item)
        self.assertEqual(db_item['estado'], 'PENDIENTE')

    def test_crear_reclamo_con_datos_faltantes(self):
        """Prueba el caso de error: intentar crear un reclamo sin todos los datos."""
        test_event = {
            "requestContext": {"http": {"method": "POST"}},
            "body": json.dumps({"descripcion": "Datos incompletos"})
        }
        response = handler(test_event, {})
        
        self.assertEqual(response['statusCode'], 400)
        self.assertIn('Faltan los campos requeridos', response['body'])

if __name__ == '__main__':
    unittest.main()