import unittest, json, os, boto3
from moto import mock_aws
from ..app import handler
from datetime import datetime, timedelta

@mock_aws
class TestLambdaControlPlazos(unittest.TestCase):
    def setUp(self):
        self.table_name = 'test-reclamos'
        os.environ['DYNAMODB_TABLE_RECLAMOS'] = self.table_name
        os.environ['SNS_TOPIC_ALERTS'] = boto3.client('sns', region_name='us-east-2').create_topic(Name='test-alerts')['TopicArn']

        dynamodb = boto3.resource('dynamodb', region_name='us-east-2')
        # GSI2: estado (HASH), fechaVencimiento (RANGE)
        dynamodb.create_table(
            TableName=self.table_name,
            KeySchema=[{'AttributeName': 'reclamoId', 'KeyType': 'HASH'}],
            AttributeDefinitions=[{'AttributeName': 'reclamoId', 'AttributeType': 'S'}, {'AttributeName': 'estado', 'AttributeType': 'S'}, {'AttributeName': 'fechaVencimiento', 'AttributeType': 'S'}],
            ProvisionedThroughput={'ReadCapacityUnits': 5, 'WriteCapacityUnits': 5},
            GlobalSecondaryIndexes=[{'IndexName': 'GSI2', 'KeySchema': [{'AttributeName': 'estado', 'KeyType': 'HASH'}, {'AttributeName': 'fechaVencimiento', 'KeyType': 'RANGE'}], 'Projection': {'ProjectionType': 'ALL'}, 'ProvisionedThroughput': {'ReadCapacityUnits': 5, 'WriteCapacityUnits': 5}}]
        )
        self.table = dynamodb.Table(self.table_name)
        vencido_ayer = (datetime.utcnow() - timedelta(days=1)).isoformat() + "Z"
        self.table.put_item(Item={'reclamoId': 'REC-VENCIDO', 'estado': 'EN_PROCESO', 'fechaVencimiento': vencido_ayer})

    def test_detecta_y_actualiza_vencidos(self):
        handler({}, None)
        item = self.table.get_item(Key={'reclamoId': 'REC-VENCIDO'})['Item']
        self.assertEqual(item['estado'], 'ATRASADO')