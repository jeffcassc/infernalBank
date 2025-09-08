from flask import Flask, request, jsonify
import boto3
from boto3.dynamodb.conditions import Key
import uuid
import base64
import json
from datetime import datetime
import jwt
from passlib.hash import pbkdf2_sha256

app = Flask(__name__)

# Configuración
dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')
users_table = dynamodb.Table('inferno-bank-dev-users')
SECRET_KEY = "your-secret-key-here"  # En producción usar Secrets Manager

@app.route('/register', methods=['POST'])
def register_user():
    try:
        data = request.get_json()
        
        # Validar campos requeridos
        required_fields = ['name', 'lastName', 'email', 'password', 'document']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Missing field: {field}'}), 400
        
        # Verificar si el usuario ya existe
        response = users_table.query(
            IndexName='document-index',
            KeyConditionExpression=Key('document').eq(data['document'])
        )
        
        if response['Items']:
            return jsonify({'error': 'User already exists'}), 409
        
        # Crear usuario
        user_id = str(uuid.uuid4())
        hashed_password = pbkdf2_sha256.hash(data['password'])
        
        user_item = {
            'uuid': user_id,
            'name': data['name'],
            'lastName': data['lastName'],
            'email': data['email'],
            'password': hashed_password,
            'document': data['document'],
            'createdAt': datetime.utcnow().isoformat()
        }
        
        users_table.put_item(Item=user_item)
        
        # Encolar creación de tarjetas
        sqs = boto3.client('sqs')
        queue_url = 'https://sqs.us-east-1.amazonaws.com/123456789012/create-request-card-sqs'
        
        # Encolar tarjeta débito
        sqs.send_message(
            QueueUrl=queue_url,
            MessageBody=json.dumps({
                'userId': user_id,
                'request': 'DEBIT'
            })
        )
        
        # Encolar tarjeta crédito
        sqs.send_message(
            QueueUrl=queue_url,
            MessageBody=json.dumps({
                'userId': user_id,
                'request': 'CREDIT'
            })
        )
        
        return jsonify({
            'message': 'User created successfully',
            'userId': user_id
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/login', methods=['POST'])
def login_user():
    try:
        data = request.get_json()
        
        if 'email' not in data or 'password' not in data:
            return jsonify({'error': 'Email and password are required'}), 400
        
        # Buscar usuario por email
        response = users_table.scan(
            FilterExpression=Key('email').eq(data['email'])
        )
        
        if not response['Items']:
            return jsonify({'error': 'Invalid credentials'}), 401
        
        user = response['Items'][0]
        
        # Verificar contraseña
        if not pbkdf2_sha256.verify(data['password'], user['password']):
            return jsonify({'error': 'Invalid credentials'}), 401
        
        # Generar JWT
        token = jwt.encode({
            'user_id': user['uuid'],
            'email': user['email'],
            'exp': datetime.utcnow().timestamp() + 3600
        }, SECRET_KEY, algorithm='HS256')
        
        return jsonify({
            'token': token,
            'user': {
                'userId': user['uuid'],
                'name': user['name'],
                'email': user['email']
            }
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)