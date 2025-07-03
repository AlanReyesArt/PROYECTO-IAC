import unittest, json, os, boto3
from moto import mock_aws
from ..app import handler

@mock_aws
class TestLambdaProcesamiento(unittest.TestCase):
    def setUp(self):
        self.table_name = 'test-reclamos'
        self.topic_arn = boto3.client('sns', region_name='us-east-2').create_topic(Name='test-topic')['TopicArn']
        os.environ['DYNAMODB_TABLE_RECLAMOS'] = self.table_name
        os.environ['SNS_TOPIC_NOTIFICATIONS'] = self.topic_arn
        
        dynamodb = boto3.resource('dynamodb', region_name='us-east-2')
        dynamodb.create_table(TableName=self.table_name, KeySchema=[{'AttributeName': 'reclamoId', 'KeyType': 'HASH'}],
                              AttributeDefinitions=[{'AttributeName': 'reclamoId', 'AttributeType': 'S'}], ProvisionedThroughput={'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1})
        self.table = dynamodb.Table(self.table_name)
        self.table.put_item(Item={'reclamoId': 'REC-123', 'fechaCreacion': '2025-01-01T00:00:00Z', 'descripcion': 'fuga de agua'})

    def test_procesa_correctamente(self):
        sqs_event = {'Records': [{'body': json.dumps({'reclamoId': 'REC-123', 'fechaCreacion': '2025-01-01T00:00:00Z', 'descripcion': 'fuga de agua'})}]}
        handler(sqs_event, None)
        item = self.table.get_item(Key={'reclamoId': 'REC-123'})['Item']
        self.assertEqual(item['estado'], 'EN_PROCESO')
        self.assertEqual(item['prioridad'], 'ALTA')