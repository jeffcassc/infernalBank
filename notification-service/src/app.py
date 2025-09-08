import json
import boto3
from email_templates import get_email_template

ses = boto3.client('ses')
s3 = boto3.client('s3')

def send_notification(event, context):
    for record in event['Records']:
        message = json.loads(record['body'])
        notification_type = message['type']
        data = message['data']
        
        # Obtener template del bucket S3
        template = get_email_template(notification_type)
        
        # Renderizar template con datos
        email_content = render_template(template, data)
        
        # Enviar email via SES
        send_email(
            to_address=data.get('email', 'user@example.com'),
            subject=f"Inferno Bank - {notification_type}",
            body=email_content
        )
    
    return {'statusCode': 200, 'body': 'Notifications sent'}

def render_template(template, data):
    # Lógica simple de renderizado
    for key, value in data.items():
        placeholder = f'{{{{{key}}}}}'
        template = template.replace(placeholder, str(value))
    return template

def send_email(to_address, subject, body):
    ses.send_email(
        Source='notifications@inferno-bank.com',
        Destination={'ToAddresses': [to_address]},
        Message={
            'Subject': {'Data': subject},
            'Body': {'Text': {'Data': body}}
        }
    )