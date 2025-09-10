# Tabla de usuarios (corregir estructura)
resource "aws_dynamodb_table" "users_table" {
  name         = "${var.project_name}-${var.environment}-users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "uuid"
  
  attribute {
    name = "uuid"
    type = "S"
  }

  attribute {
    name = "document"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  global_secondary_index {
    name               = "document-index"
    hash_key           = "document"
    projection_type    = "ALL"
    write_capacity     = 5
    read_capacity      = 5
  }

  global_secondary_index {
    name               = "email-index"
    hash_key           = "email"
    projection_type    = "ALL"
    write_capacity     = 5
    read_capacity      = 5
  }

  tags = {
    Name        = "${var.project_name}-users-table"
    Environment = var.environment
  }
}

# Tabla de notificaciones (nueva)
resource "aws_dynamodb_table" "notifications_table" {
  name         = "${var.project_name}-${var.environment}-notifications"
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
    Name        = "${var.project_name}-notifications-table"
    Environment = var.environment
  }
}

# Tabla de errores de notificaciones (nueva)
resource "aws_dynamodb_table" "notification_errors_table" {
  name         = "${var.project_name}-${var.environment}-notification-errors"
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
    Name        = "${var.project_name}-notification-errors-table"
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


# Politica para Lambda (ampliada)
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
          "dynamodb:Scan",
          "dynamodb:BatchWriteItem"
        ]
        Resource = [
          aws_dynamodb_table.users_table.arn,
          aws_dynamodb_table.cards_table.arn,
          aws_dynamodb_table.transactions_table.arn,
          aws_dynamodb_table.notifications_table.arn,
          aws_dynamodb_table.notification_errors_table.arn,
          aws_dynamodb_table.card_errors_table.arn,
          "${aws_dynamodb_table.users_table.arn}/index/*",
          "${aws_dynamodb_table.cards_table.arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-${var.environment}-avatars/*",
          "arn:aws:s3:::${var.project_name}-${var.environment}-avatars",
          "arn:aws:s3:::${var.project_name}-${var.environment}-reports/*",
          "arn:aws:s3:::${var.project_name}-${var.environment}-reports",
          "arn:aws:s3:::${var.project_name}-${var.environment}-email-templates/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:*:secret:${var.project_name}-${var.environment}-*"
      }
    ]
  })
}
resource "aws_iam_policy" "lambda_sqs_policy" {
  name = "${var.project_name}-${var.environment}-lambda-sqs-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
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
    aws_api_gateway_integration.register_integration,
    aws_api_gateway_integration.login_integration,
    aws_api_gateway_integration.profile_put_integration,
    aws_api_gateway_integration.avatar_post_integration,
    aws_api_gateway_integration.profile_get_integration,
    aws_api_gateway_integration.card_activate_integration,
    aws_api_gateway_integration.transactions_purchase_integration,
    aws_api_gateway_integration.transactions_save_integration,
    aws_api_gateway_integration.card_paid_integration,
    aws_api_gateway_integration.card_get_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.main_api.id
}

resource "aws_api_gateway_stage" "api_stage" {
  stage_name    = var.environment
  rest_api_id   = aws_api_gateway_rest_api.main_api.id
  deployment_id = aws_api_gateway_deployment.api_deployment.id
}

# Agrega esto después de aws_api_gateway_rest_api
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.main_api.id
  resource_id = aws_api_gateway_resource.example_resource.id
  http_method = aws_api_gateway_method.example_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.register_user_lambda.invoke_arn
}

resource "aws_api_gateway_integration" "card_activate_integration" {
  rest_api_id             = aws_api_gateway_rest_api.main_api.id
  resource_id             = aws_api_gateway_resource.card_activate_resource.id
  http_method             = aws_api_gateway_method.card_activate_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.card_activate_lambda.invoke_arn
}

resource "aws_api_gateway_integration" "transactions_purchase_integration" {
  rest_api_id             = aws_api_gateway_rest_api.main_api.id
  resource_id             = aws_api_gateway_resource.transactions_purchase_resource.id
  http_method             = aws_api_gateway_method.transactions_purchase_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.card_purchase_lambda.invoke_arn
}


resource "aws_api_gateway_integration" "transactions_save_integration" {
  rest_api_id             = aws_api_gateway_rest_api.main_api.id
  resource_id             = aws_api_gateway_resource.transactions_save_resource.id
  http_method             = aws_api_gateway_method.transactions_save_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.card_save_lambda.invoke_arn
}


resource "aws_api_gateway_integration" "card_paid_integration" {
  rest_api_id             = aws_api_gateway_rest_api.main_api.id
  resource_id             = aws_api_gateway_resource.card_paid_resource.id
  http_method             = aws_api_gateway_method.card_paid_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.card_paid_lambda.invoke_arn
}

resource "aws_api_gateway_integration" "card_get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.main_api.id
  resource_id             = aws_api_gateway_resource.card_id_resource.id
  http_method             = aws_api_gateway_method.card_get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.card_report_lambda.invoke_arn
}





# También necesitas estos recursos:
resource "aws_api_gateway_resource" "example_resource" {
  rest_api_id = aws_api_gateway_rest_api.main_api.id
  parent_id   = aws_api_gateway_rest_api.main_api.root_resource_id
  path_part   = "example"
}

resource "aws_api_gateway_method" "example_method" {
  rest_api_id   = aws_api_gateway_rest_api.main_api.id
  resource_id   = aws_api_gateway_resource.example_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway - Recursos y métodos adicionales
resource "aws_api_gateway_resource" "profile_resource" {
  rest_api_id = aws_api_gateway_rest_api.main_api.id
  parent_id   = aws_api_gateway_rest_api.main_api.root_resource_id
  path_part   = "profile"
}

resource "aws_api_gateway_resource" "profile_id_resource" {
  rest_api_id = aws_api_gateway_rest_api.main_api.id
  parent_id   = aws_api_gateway_resource.profile_resource.id
  path_part   = "{user_id}"
}

resource "aws_api_gateway_resource" "avatar_resource" {
  rest_api_id = aws_api_gateway_rest_api.main_api.id
  parent_id   = aws_api_gateway_resource.profile_id_resource.id
  path_part   = "avatar"
}

resource "aws_api_gateway_resource" "card_resource" {
  rest_api_id = aws_api_gateway_rest_api.main_api.id
  parent_id   = aws_api_gateway_rest_api.main_api.root_resource_id
  path_part   = "card"
}

resource "aws_api_gateway_resource" "card_activate_resource" {
  rest_api_id = aws_api_gateway_rest_api.main_api.id
  parent_id   = aws_api_gateway_resource.card_resource.id
  path_part   = "activate"
}

resource "aws_api_gateway_resource" "transactions_resource" {
  rest_api_id = aws_api_gateway_rest_api.main_api.id
  parent_id   = aws_api_gateway_rest_api.main_api.root_resource_id
  path_part   = "transactions"
}

resource "aws_api_gateway_resource" "transactions_purchase_resource" {
  rest_api_id = aws_api_gateway_rest_api.main_api.id
  parent_id   = aws_api_gateway_resource.transactions_resource.id
  path_part   = "purchase"
}

resource "aws_api_gateway_resource" "transactions_save_resource" {
  rest_api_id = aws_api_gateway_rest_api.main_api.id
  parent_id   = aws_api_gateway_resource.transactions_resource.id
  path_part   = "save"
}

resource "aws_api_gateway_resource" "card_paid_resource" {
  rest_api_id = aws_api_gateway_rest_api.main_api.id
  parent_id   = aws_api_gateway_resource.card_resource.id
  path_part   = "paid"
}

resource "aws_api_gateway_resource" "card_id_resource" {
  rest_api_id = aws_api_gateway_rest_api.main_api.id
  parent_id   = aws_api_gateway_resource.card_resource.id
  path_part   = "{card_id}"
}

# /register
resource "aws_api_gateway_resource" "register_resource" {
  rest_api_id = aws_api_gateway_rest_api.main_api.id
  parent_id   = aws_api_gateway_rest_api.main_api.root_resource_id
  path_part   = "register"
}

resource "aws_api_gateway_method" "register_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.main_api.id
  resource_id   = aws_api_gateway_resource.register_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "register_integration" {
  rest_api_id             = aws_api_gateway_rest_api.main_api.id
  resource_id             = aws_api_gateway_resource.register_resource.id
  http_method             = aws_api_gateway_method.register_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.register_user_lambda.invoke_arn
}

# /login
resource "aws_api_gateway_resource" "login_resource" {
  rest_api_id = aws_api_gateway_rest_api.main_api.id
  parent_id   = aws_api_gateway_rest_api.main_api.root_resource_id
  path_part   = "login"
}

# Métodos para cada endpoint
resource "aws_api_gateway_method" "profile_put_method" {
  rest_api_id   = aws_api_gateway_rest_api.main_api.id
  resource_id   = aws_api_gateway_resource.profile_id_resource.id
  http_method   = "PUT"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "avatar_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.main_api.id
  resource_id   = aws_api_gateway_resource.avatar_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "profile_get_method" {
  rest_api_id   = aws_api_gateway_rest_api.main_api.id
  resource_id   = aws_api_gateway_resource.profile_id_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "card_activate_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.main_api.id
  resource_id   = aws_api_gateway_resource.card_activate_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "transactions_purchase_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.main_api.id
  resource_id   = aws_api_gateway_resource.transactions_purchase_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "transactions_save_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.main_api.id
  resource_id   = aws_api_gateway_resource.transactions_save_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "card_paid_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.main_api.id
  resource_id   = aws_api_gateway_resource.card_paid_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "card_get_method" {
  rest_api_id   = aws_api_gateway_rest_api.main_api.id
  resource_id   = aws_api_gateway_resource.card_id_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "login_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.main_api.id
  resource_id   = aws_api_gateway_resource.login_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integraciones para cada método
resource "aws_api_gateway_integration" "profile_put_integration" {
  rest_api_id             = aws_api_gateway_rest_api.main_api.id
  resource_id             = aws_api_gateway_resource.profile_id_resource.id
  http_method             = aws_api_gateway_method.profile_put_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.update_user_lambda.invoke_arn
}

resource "aws_api_gateway_integration" "avatar_post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.main_api.id
  resource_id             = aws_api_gateway_resource.avatar_resource.id
  http_method             = aws_api_gateway_method.avatar_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.upload_avatar_lambda.invoke_arn
}

resource "aws_api_gateway_integration" "profile_get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.main_api.id
  resource_id             = aws_api_gateway_resource.profile_id_resource.id
  http_method             = aws_api_gateway_method.profile_get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_profile_lambda.invoke_arn
}

resource "aws_api_gateway_integration" "login_integration" {
  rest_api_id             = aws_api_gateway_rest_api.main_api.id
  resource_id             = aws_api_gateway_resource.login_resource.id
  http_method             = aws_api_gateway_method.login_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.login_user_lambda.invoke_arn
}

# Agrega esto junto con las otras definiciones de tablas DynamoDB
resource "aws_dynamodb_table" "card_errors_table" {
  name         = "${var.project_name}-${var.environment}-card-errors"
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
    Name        = "${var.project_name}-card-errors-table"
    Environment = var.environment
  }
}



