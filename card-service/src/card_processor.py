import json
import boto3
import uuid
import random
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
sqs = boto3.client('sqs')

def process_card_request(event, context):
    cards_table = dynamodb.Table('inferno-bank-dev-cards')
    notification_queue_url = 'https://sqs.us-east-1.amazonaws.com/123456789012/notification-queue'
    
    for record in event['Records']:
        message = json.loads(record['body'])
        user_id = message['userId']
        card_type = message['request']
        
        # Generar score aleatorio para tarjetas de crédito
        score = random.randint(0, 100) if card_type == "CREDIT" else 100
        
        # Calcular balance basado en score
        if card_type == "CREDIT":
            amount = 100 + (score / 100) * (10000000 - 100)
            status = "PENDING" if score < 70 else "APPROVED"
        else:
            amount = 0
            status = "ACTIVATED"
        
        # Crear tarjeta
        card_id = str(uuid.uuid4())
        card_item = {
            'uuid': card_id,
            'user_id': user_id,
            'type': card_type,
            'status': status,
            'balance': amount,
            'createdAt': datetime.utcnow().isoformat()
        }
        
        cards_table.put_item(Item=card_item)
        
        # Enviar notificación
        notification_message = {
            'type': 'CARD.CREATE',
            'data': {
                'userId': user_id,
                'cardId': card_id,
                'type': card_type,
                'amount': amount,
                'status': status,
                'date': datetime.utcnow().isoformat()
            }
        }
        
        sqs.send_message(
            QueueUrl=notification_queue_url,
            MessageBody=json.dumps(notification_message)
        )
    
    return {'statusCode': 200, 'body': 'Cards processed successfully'}