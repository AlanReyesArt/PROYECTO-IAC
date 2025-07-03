import unittest, json, os, boto3
from moto import mock_aws
from ..app import handler

@mock_aws
class TestLambdaNotificaciones(unittest.TestCase):
    def setUp(self):
        os.environ['FROM_EMAIL'] = 'noreply@example.com'
        os.environ['DYNAMODB_TABLE_CIUDADANOS'] = 'test-ciudadanos'
        ses = boto3.client('ses', region_name='us-east-2')
        ses.verify_email_identity(EmailAddress='noreply@example.com')

    def test_envia_email_correctamente(self):
        sns_message = {'detail': {'reclamoId': 'REC-456', 'ciudadanoId': 'test-user', 'nuevoEstado': 'EN_PROCESO'}}
        sns_event = {'Records': [{'Sns': {'Message': json.dumps(sns_message)}}]}
        
        # Esta es la forma de acceder al mock de SES después de la ejecución
        with mock_aws():
            ses_client = boto3.client("ses", region_name="us-east-2")
            ses_client.verify_email_identity(EmailAddress="noreply@example.com")
            
            handler(sns_event, None)
            
            sent_data = ses_client.get_send_quota()['SentLast24Hours']
            self.assertEqual(sent_data, 1)