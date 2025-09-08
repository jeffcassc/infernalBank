import boto3
import json
import base64
import uuid
from datetime import datetime

def send_sqs_message(queue_url, message_body):
    sqs = boto3.client('sqs')
    response = sqs.send_message(
        QueueUrl=queue_url,
        MessageBody=json.dumps(message_body)
    )
    return response

def upload_to_s3(bucket_name, file_content, file_name, content_type):
    s3 = boto3.client('s3')
    s3.put_object(
        Bucket=bucket_name,
        Key=file_name,
        Body=file_content,
        ContentType=content_type
    )
    return f"https://{bucket_name}.s3.amazonaws.com/{file_name}"

def decode_base64_image(base64_string):
    if ',' in base64_string:
        base64_string = base64_string.split(',')[1]
    return base64.b64decode(base64_string)

def generate_presigned_url(bucket_name, object_name, expiration=3600):
    s3 = boto3.client('s3')
    return s3.generate_presigned_url(
        'get_object',
        Params={'Bucket': bucket_name, 'Key': object_name},
        ExpiresIn=expiration
    )