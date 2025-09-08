# Tabla de usuarios
resource "aws_dynamodb_table" "users_table" {
  name         = "${var.project_name}-${var.environment}-users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "uuid"
  range_key    = "document"

  attribute {
    name = "uuid"
    type = "S"
  }

  attribute {
    name = "document"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}-users-table"
    Environment = var.environment
  }
}

# Tabla de tarjetas
resource "aws_dynamodb_table" "cards_table" {
  name         = "${var.project_name}-${var.environment}-cards"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "uuid"
  range_key    = "createdAt"

  attribute {
    name = "uuid"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}-cards-table"
    Environment = var.environment
  }
}

# Tabla de transacciones
resource "aws_dynamodb_table" "transactions_table" {
  name         = "${var.project_name}-${var.environment}-transactions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "uuid"
  range_key    = "createdAt"

  attribute {
    name = "uuid"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}-transactions-table"
    Environment = var.environment
  }
}
# IAM Role para Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Politica para Lambda
resource "aws_iam_policy" "lambda_policy" {
  name = "${var.project_name}-${var.environment}-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.users_table.arn,
          aws_dynamodb_table.cards_table.arn,
          aws_dynamodb_table.transactions_table.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.project_name}-${var.environment}-avatars/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Adjuntar política al rol
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Bucket S3 para avatares
resource "aws_s3_bucket" "avatars_bucket" {
  bucket = "${var.project_name}-${var.environment}-avatars"
  
  tags = {
    Name        = "${var.project_name}-avatars-bucket"
    Environment = var.environment
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "main_api" {
  name        = "${var.project_name}-${var.environment}-api"
  description = "API para Inferno Bank"
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.main_api.id
  stage_name  = var.environment
}