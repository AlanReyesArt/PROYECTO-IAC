import unittest
import os
import json
import sys
import boto3
from moto import mock_aws

# Agregamos el directorio 'src' al path para que Python encuentre los módulos
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# Establecemos las variables de entorno ANTES de importar la app
os.environ['AWS_REGION'] = 'us-east-1'
os.environ['AWS_DEFAULT_REGION'] = 'us-east-1'
os.environ['DYNAMODB_TABLE_RECLAMOS'] = 'tabla-test-reclamos'
os.environ['SQS_QUEUE_URL'] = 'https://sqs.us-east-1.amazonaws.com/123456789012/cola-test'

# Importamos el handler de forma segura
from src.lambda_reclamos.app import handler

@mock_aws
class TestLambdaReclamos(unittest.TestCase):

    def setUp(self):
        """
        Crea los recursos simulados antes de cada prueba.
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

    # --- PRUEBA 1 (EXISTENTE) ---
    def test_crear_reclamo_exitoso(self):
        """Prueba el caso de éxito con datos válidos."""
        test_event = {
            "requestContext": {"http": {"method": "POST"}},
            "body": json.dumps({
                "descripcion": "Poste de luz roto.",
                "ciudadanoId": "ciudadano-007"
            })
        }
        response = handler(test_event, {})
        self.assertEqual(response['statusCode'], 201)

    # --- PRUEBA 2 (EXISTENTE) ---
    def test_crear_reclamo_con_datos_faltantes(self):
        """Prueba el caso de error cuando faltan campos requeridos."""
        test_event = {
            "requestContext": {"http": {"method": "POST"}},
            "body": json.dumps({"descripcion": "Datos incompletos"})
        }
        response = handler(test_event, {})
        self.assertEqual(response['statusCode'], 400)
        self.assertIn('Faltan los campos requeridos', response['body'])

    # --- PRUEBA 3 (NUEVA) ---
    def test_metodo_http_no_permitido(self):
        """Prueba que la Lambda rechace métodos que no sean POST."""
        test_event = {
            "requestContext": {"http": {"method": "GET"}} # Usamos GET
        }
        response = handler(test_event, {})
        self.assertEqual(response['statusCode'], 405)
        self.assertIn('Método no permitido', response['body'])

    # --- PRUEBA 4 (NUEVA) ---
    def test_body_vacio_o_ausente(self):
        """Prueba el manejo de una petición sin cuerpo (body)."""
        test_event = {
            "requestContext": {"http": {"method": "POST"}},
            "body": None # Sin cuerpo
        }
        response = handler(test_event, {})
        self.assertEqual(response['statusCode'], 400)
        self.assertIn('Cuerpo de la petición inválido', response['body'])

    # --- PRUEBA 5 (NUEVA) ---
    def test_json_malformado_en_body(self):
        """Prueba el manejo de un cuerpo que no es un JSON válido."""
        test_event = {
            "requestContext": {"http": {"method": "POST"}},
            "body": "{'descripcion': 'esto no es un JSON valido'" # JSON con comillas simples
        }
        response = handler(test_event, {})
        self.assertEqual(response['statusCode'], 400)
        self.assertIn('Cuerpo de la petición inválido', response['body'])

if __name__ == '__main__':
    unittest.main()