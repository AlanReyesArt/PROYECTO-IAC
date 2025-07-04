import unittest
import os
import json
import sys
import boto3
from moto import mock_aws


sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))


os.environ['AWS_REGION'] = 'us-east-2'
os.environ['AWS_DEFAULT_REGION'] = 'us-east-2'
os.environ['DYNAMODB_TABLE_RECLAMOS'] = 'tabla-test-reclamos'
os.environ['SQS_QUEUE_URL'] = 'https://sqs.us-east-2.amazonaws.com/123456789012/cola-test'


from src.lambda_reclamos.app import handler

@mock_aws
class TestLambdaReclamos(unittest.TestCase):

    def setUp(self):
        """
        Crea los recursos simulados. Boto3 usará automáticamente la región
        que definimos arriba en las variables de entorno.
        """
        # Setup SQS
        sqs = boto3.client('sqs')
        sqs.create_queue(QueueName='cola-test')
        
        # Setup DynamoDB
        dynamodb = boto3.resource('dynamodb')
        dynamodb.create_table(
            TableName=os.environ['DYNAMODB_TABLE_RECLAMOS'],
            KeySchema=[{'AttributeName': 'reclamoId', 'KeyType': 'HASH'}],
            AttributeDefinitions=[{'AttributeName': 'reclamoId', 'AttributeType': 'S'}],
            ProvisionedThroughput={'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1}
        )
        self.dynamodb_table = dynamodb.Table(os.environ['DYNAMODB_TABLE_RECLAMOS'])

    def test_crear_reclamo_exitoso(self):
        """Prueba el caso de éxito."""
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
        
        db_item = self.dynamodb_table.get_item(Key={'reclamoId': response_body['reclamoId']}).get('Item')
        
        self.assertIsNotNone(db_item)
        self.assertEqual(db_item['estado'], 'PENDIENTE')

    def test_crear_reclamo_con_datos_faltantes(self):
        """Prueba el caso de error."""
        test_event = {
            "requestContext": {"http": {"method": "POST"}},
            "body": json.dumps({"descripcion": "Datos incompletos"})
        }
        response = handler(test_event, {})
        
        self.assertEqual(response['statusCode'], 400)
        self.assertIn('Faltan los campos requeridos', response['body'])

if __name__ == '__main__':
    unittest.main()