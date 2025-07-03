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
        # Especificamos la región para el cliente SQS
        sqs = boto3.client('sqs', region_name=os.environ['AWS_REGION'])
        sqs.create_queue(QueueName='cola-test')
        
        # Setup DynamoDB
        # Especificamos la región para el recurso DynamoDB
        dynamodb = boto3.resource('dynamodb', region_name=os.environ['AWS_REGION'])
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
        response_body = json.loads(response['body'])
        self.assertIn('Reclamo creado exitosamente', response_body['message'])
        self.assertIn('reclamoId', response_body)

        # Verificar el elemento en DynamoDB
        item = self.dynamodb_table.get_item(Key={'reclamoId': response_body['reclamoId']})
        self.assertIsNotNone(item.get('Item'))
        self.assertEqual(item['Item']['descripcion'], "Poste de luz roto.")
        self.assertEqual(item['Item']['ciudadanoId'], "ciudadano-007")
        self.assertEqual(item['Item']['estado'], "PENDIENTE")

        # Verificar el mensaje en SQS
        sqs = boto3.client('sqs', region_name=os.environ['AWS_REGION'])
        queue_url = os.environ['SQS_QUEUE_URL']
        # Recibir mensajes de la cola SQS
        messages = sqs.receive_message(QueueUrl=queue_url, MaxNumberOfMessages=1)
        self.assertIn('Messages', messages)
        # Parsear el cuerpo del mensaje SQS
        sqs_message_body = json.loads(messages['Messages'][0]['Body'])
        self.assertEqual(sqs_message_body['reclamoId'], response_body['reclamoId'])
        self.assertEqual(sqs_message_body['descripcion'], "Poste de luz roto.")
        self.assertEqual(sqs_message_body['ciudadanoId'], "ciudadano-007")
        self.assertEqual(sqs_message_body['estado'], "PENDIENTE")


    # --- PRUEBA 2 (EXISTENTE) ---
    def test_crear_reclamo_con_datos_faltantes(self):
        """Prueba el caso de error cuando faltan campos requeridos."""
        test_event = {
            "requestContext": {"http": {"method": "POST"}},
            "body": json.dumps({"descripcion": "Datos incompletos"}) # Falta ciudadanoId
        }
        response = handler(test_event, {})
        self.assertEqual(response['statusCode'], 400)
        response_body = json.loads(response['body'])
        self.assertIn('Faltan los campos requeridos', response_body['message'])

    # --- PRUEBA 3 (NUEVA) ---
    def test_metodo_http_no_permitido(self):
        """Prueba que la Lambda rechace métodos que no sean POST."""
        test_event = {
            "requestContext": {"http": {"method": "GET"}}, # Usamos GET
            "body": "{}" # Un cuerpo vacío es aceptable para un método no permitido
        }
        response = handler(test_event, {})
        self.assertEqual(response['statusCode'], 405)
        response_body = json.loads(response['body'])
        self.assertIn('Método no permitido. Solo se acepta POST.', response_body['message'])

    # --- PRUEBA 4 (NUEVA) ---
    def test_body_vacio_o_ausente(self):
        """Prueba el manejo de una petición sin cuerpo (body) o con cuerpo vacío."""
        # Caso de prueba 1: 'body' es explícitamente None
        test_event_none_body = {
            "requestContext": {"http": {"method": "POST"}},
            "body": None # Cuerpo explícitamente None
        }
        response_none = handler(test_event_none_body, {})
        self.assertEqual(response_none['statusCode'], 400)
        response_body_none = json.loads(response_none['body'])
        self.assertIn('Cuerpo de la petición ausente.', response_body_none['message'])

        # Caso de prueba 2: 'body' es una cadena vacía
        test_event_empty_body = {
            "requestContext": {"http": {"method": "POST"}},
            "body": "" # Cuerpo como cadena vacía
        }
        response_empty = handler(test_event_empty_body, {})
        self.assertEqual(response_empty['statusCode'], 400)
        response_body_empty = json.loads(response_empty['body'])
        self.assertIn('Cuerpo de la petición inválido. Debe ser un JSON válido.', response_body_empty['message'])


    # --- PRUEBA 5 (NUEVA) ---
    def test_json_malformado_en_body(self):
        """Prueba el manejo de un cuerpo que no es un JSON válido."""
        test_event = {
            "requestContext": {"http": {"method": "POST"}},
            "body": "{'descripcion': 'esto no es un JSON valido'" # JSON con comillas simples (inválido)
        }
        response = handler(test_event, {})
        self.assertEqual(response['statusCode'], 400)
        response_body = json.loads(response['body'])
        self.assertIn('Cuerpo de la petición inválido. Debe ser un JSON válido.', response_body['message'])

if __name__ == '__main__':
    unittest.main()