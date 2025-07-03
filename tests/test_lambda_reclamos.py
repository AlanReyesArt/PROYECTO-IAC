import unittest
import os
import json
import sys
import boto3
from moto import mock_aws

# --- INICIO DE LA CORRECCIÓN ---
# 1. Agregamos el directorio 'src' al path para que Python encuentre los módulos
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# 2. Creamos un contexto de AWS simulado y definimos TODAS las variables ANTES de importar la app
@mock_aws
def setup_mock_environment():
    # Definimos el nombre de la tabla y la cola
    table_name = 'tabla-test-reclamos'
    queue_name = 'cola-test'
    aws_region = 'us-east-2'
    
    # Creamos la cola SQS simulada y obtenemos su URL
    sqs = boto3.client('sqs', region_name=aws_region)
    sqs_response = sqs.create_queue(QueueName=queue_name)
    
    # Ponemos las variables de entorno que la aplicación necesita para importarse
    os.environ['SQS_QUEUE_URL'] = sqs_response['QueueUrl']
    os.environ['DYNAMODB_TABLE_RECLAMOS'] = table_name

# Ejecutamos la función para que las variables de entorno existan
setup_mock_environment()
# ----------------------------------------------------------------

# 3. AHORA SÍ importamos el handler, una vez que las variables ya existen
from src.lambda_reclamos.app import handler

@mock_aws
class TestLambdaReclamos(unittest.TestCase):

    def setUp(self):
        """
        Este método ahora solo se encarga de crear los recursos de AWS simulados
        usando los nombres de las variables de entorno que ya existen.
        """
        aws_region = 'us-east-2'
        
        # Setup DynamoDB
        dynamodb = boto3.resource('dynamodb', region_name=aws_region)
        table_name = os.environ['DYNAMODB_TABLE_RECLAMOS']
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
        test_event = {
            "requestContext": {"http": {"method": "POST"}},
            "body": json.dumps({
                "descripcion": "Poste de luz roto en la plaza principal.",
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
        self.assertEqual(db_item['ciudadanoId'], 'ciudadano-007')
        self.assertEqual(db_item['estado'], 'PENDIENTE')

    def test_crear_reclamo_con_datos_faltantes(self):
        """
        Prueba el caso de error: intentar crear un reclamo sin todos los datos.
        """
        test_event = {
            "requestContext": {"http": {"method": "POST"}},
            "body": json.dumps({"descripcion": "Datos incompletos"})
        }
        response = handler(test_event, {})
        
        self.assertEqual(response['statusCode'], 400)
        self.assertIn('Faltan los campos requeridos', response['body'])

if __name__ == '__main__':
    unittest.main()