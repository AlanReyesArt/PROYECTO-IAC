import unittest, json, os, boto3
from moto import mock_aws
from ..app import handler

@mock_aws
class TestLambdaReportes(unittest.TestCase):
    def setUp(self):
        self.table_name = 'test-reclamos'
        os.environ['DYNAMODB_TABLE_RECLAMOS'] = self.table_name
        dynamodb = boto3.resource('dynamodb', region_name='us-east-2')
        dynamodb.create_table(TableName=self.table_name, KeySchema=[{'AttributeName': 'reclamoId', 'KeyType': 'HASH'}],
                              AttributeDefinitions=[{'AttributeName': 'reclamoId', 'AttributeType': 'S'}], ProvisionedThroughput={'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1})
        table = dynamodb.Table(self.table_name)
        table.put_item(Item={'reclamoId': '1', 'tipo': 'AGUA'})
        table.put_item(Item={'reclamoId': '2', 'tipo': 'LUZ'})

    def test_reporte_sin_filtro(self):
        respuesta = handler({}, None)
        self.assertEqual(respuesta['statusCode'], 200)
        body = json.loads(respuesta['body'])
        self.assertEqual(body['totalReclamos'], 2)