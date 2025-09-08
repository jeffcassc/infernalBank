#!/bin/bash

# Variables
PROJECT_NAME="inferno-bank"
ENVIRONMENT="dev"
REGION="us-east-1"

echo "Desplegando Inferno Bank..."

# Configurar AWS CLI
aws configure set region $REGION

# Construir y desplegar Lambdas
echo "Construyendo servicios..."
cd user-service
pip install -r requirements.txt -t .
zip -r ../deploy.zip .
cd ..

# Aplicar Terraform
cd terraform
terraform init
terraform apply -auto-approve

echo "Despliegue completado!"