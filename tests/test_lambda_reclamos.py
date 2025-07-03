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

@mock_aws
class TestLambdaReclamos(unittest.TestCase):

    def setUp(self):
        """
        Este método se ejecuta ANTES de cada prueba.
        Crea los recursos de AWS simulados (mock) que necesitamos.
        """
        import boto3
        
        # Corregido: La variable de SQS también debe definirse aquí
        sqs = boto3.client('sqs', region_name='us-east-1')
        response = sqs.create_queue(QueueName='cola-test')
        os.environ['SQS_QUEUE_URL'] = response['QueueUrl']
        
        # Setup DynamoDB
        dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
        dynamodb.create_table(
            TableName='tabla-test-reclamos',
            KeySchema=[{'AttributeName': 'reclamoId', 'KeyType': 'HASH'}],
            AttributeDefinitions=[{'AttributeName': 'reclamoId', 'AttributeType': 'S'}],
            ProvisionedThroughput={'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1}
        )
        self.dynamodb_table = dynamodb.Table('tabla-test-reclamos')

    def test_crear_reclamo_exitoso(self):
        """
        Prueba el caso de éxito: crear un reclamo con datos válidos.
        """
        # 1. PREPARACIÓN
        test_event = {
            "requestContext": {"http": {"method": "POST"}},
            "body": json.dumps({
                "descripcion": "Poste de luz roto en la plaza principal.",
                "ciudadanoId": "ciudadano-007"
            })
        }

        # 2. EJECUCIÓN
        response = handler(test_event, {})
        
        # 3. VERIFICACIÓN
        self.assertEqual(response['statusCode'], 201)
        response_body = json.loads(response['body'])
        self.assertIn('reclamoId', response_body)
        
        reclamo_id = response_body['reclamoId']
        db_item = self.dynamodb_table.get_item(Key={'reclamoId': reclamo_id}).get('Item')
        
        self.assertIsNotNone(db_item)
        self.assertEqual(db_item['ciudadanoId'], 'ciudadano-007')
        self.assertEqual(db_item['estado'], 'PENDIENTE')

    def test_crear_reclamo_con_datos_faltantes(self):
        """
        Prueba el caso de error: intentar crear un reclamo sin todos los datos.
        """
        # 1. PREPARACIÓN
        test_event = {
            "requestContext": {"http": {"method": "POST"}},
            "body": json.dumps({"descripcion": "Datos incompletos"})
        }
        
        # 2. EJECUCIÓN
        response = handler(test_event, {})
        
        # 3. VERIFICACIÓN
        self.assertEqual(response['statusCode'], 400)
        self.assertIn('Faltan los campos', response['body'])

# Corregido con doble guion bajo
if __name__ == '__main__':
    unittest.main()