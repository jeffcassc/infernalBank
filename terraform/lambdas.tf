# Lambda para registro de usuarios
resource "aws_lambda_function" "register_user_lambda" {
  filename      = "../user-service/deploy.zip"
  function_name = "${var.project_name}-${var.environment}-register-user"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.register_user"
  runtime       = "python3.9"
  timeout       = 30

  environment {
    variables = {
      USERS_TABLE    = aws_dynamodb_table.users_table.name
      CARDS_QUEUE    = aws_sqs_queue.create_card_queue.url
      NOTIFY_QUEUE   = aws_sqs_queue.notification_queue.url
    }
  }
}

# Lambda para login
resource "aws_lambda_function" "login_user_lambda" {
  filename      = "../user-service/deploy.zip"
  function_name = "${var.project_name}-${var.environment}-login-user"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.login_user"
  runtime       = "python3.9"
}

# Lambda para procesar tarjetas
resource "aws_lambda_function" "card_processor_lambda" {
  filename      = "../card-service/deploy.zip"
  function_name = "${var.project_name}-${var.environment}-card-processor"
  role          = aws_iam_role.lambda_role.arn
  handler       = "card_processor.process_card_request"
  runtime       = "python3.9"

  environment {
    variables = {
      CARDS_TABLE    = aws_dynamodb_table.cards_table.name
      NOTIFY_QUEUE   = aws_sqs_queue.notification_queue.url
    }
  }
}

# Trigger para SQS -> Lambda
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.create_card_queue.arn
  function_name    = aws_lambda_function.card_processor_lambda.arn
  batch_size       = 1
}

# También necesitas el IAM role para la Lambda
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
# Lambda para actualizar usuario
resource "aws_lambda_function" "update_user_lambda" {
  filename      = "../user-service/deploy.zip"
  function_name = "${var.project_name}-${var.environment}-update-user"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.update_user"
  runtime       = "python3.9"
  timeout       = 30

  environment {
    variables = {
      USERS_TABLE = aws_dynamodb_table.users_table.name
    }
  }
}

# Lambda para subir avatar
resource "aws_lambda_function" "upload_avatar_lambda" {
  filename      = "../user-service/deploy.zip"
  function_name = "${var.project_name}-${var.environment}-upload-avatar"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.upload_avatar"
  runtime       = "python3.9"
  timeout       = 30

  environment {
    variables = {
      USERS_TABLE = aws_dynamodb_table.users_table.name
      AVATARS_BUCKET = aws_s3_bucket.avatars_bucket.bucket
    }
  }
}

# Lambda para obtener perfil
resource "aws_lambda_function" "get_profile_lambda" {
  filename      = "../user-service/deploy.zip"
  function_name = "${var.project_name}-${var.environment}-get-profile"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.get_profile"
  runtime       = "python3.9"
  timeout       = 30

  environment {
    variables = {
      USERS_TABLE = aws_dynamodb_table.users_table.name
    }
  }
}

# Lambda para activar tarjeta
resource "aws_lambda_function" "card_activate_lambda" {
  filename      = "../card-service/deploy.zip"
  function_name = "${var.project_name}-${var.environment}-card-activate"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.activate_card"
  runtime       = "python3.9"
  timeout       = 30

  environment {
    variables = {
      CARDS_TABLE = aws_dynamodb_table.cards_table.name
      NOTIFY_QUEUE = aws_sqs_queue.notification_queue.url
    }
  }
}

# Lambda para compras con tarjeta
resource "aws_lambda_function" "card_purchase_lambda" {
  filename      = "../card-service/deploy.zip"
  function_name = "${var.project_name}-${var.environment}-card-purchase"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.purchase"
  runtime       = "python3.9"
  timeout       = 30

  environment {
    variables = {
      CARDS_TABLE = aws_dynamodb_table.cards_table.name
      TRANSACTIONS_TABLE = aws_dynamodb_table.transactions_table.name
      NOTIFY_QUEUE = aws_sqs_queue.notification_queue.url
    }
  }
}

# Lambda para ahorros
resource "aws_lambda_function" "card_save_lambda" {
  filename      = "../card-service/deploy.zip"
  function_name = "${var.project_name}-${var.environment}-card-save"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.save_money"
  runtime       = "python3.9"
  timeout       = 30

  environment {
    variables = {
      CARDS_TABLE = aws_dynamodb_table.cards_table.name
      TRANSACTIONS_TABLE = aws_dynamodb_table.transactions_table.name
      NOTIFY_QUEUE = aws_sqs_queue.notification_queue.url
    }
  }
}

# Lambda para pagar tarjeta de crédito
resource "aws_lambda_function" "card_paid_lambda" {
  filename      = "../card-service/deploy.zip"
  function_name = "${var.project_name}-${var.environment}-card-paid"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.pay_credit_card"
  runtime       = "python3.9"
  timeout       = 30

  environment {
    variables = {
      CARDS_TABLE = aws_dynamodb_table.cards_table.name
      TRANSACTIONS_TABLE = aws_dynamodb_table.transactions_table.name
      NOTIFY_QUEUE = aws_sqs_queue.notification_queue.url
    }
  }
}

# Lambda para reportes
resource "aws_lambda_function" "card_report_lambda" {
  filename      = "../card-service/deploy.zip"
  function_name = "${var.project_name}-${var.environment}-card-report"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.generate_report"
  runtime       = "python3.9"
  timeout       = 60

  environment {
    variables = {
      TRANSACTIONS_TABLE = aws_dynamodb_table.transactions_table.name
      REPORTS_BUCKET = aws_s3_bucket.transactions_reports_bucket.bucket
      NOTIFY_QUEUE = aws_sqs_queue.notification_queue.url
    }
  }
}

# Lambda para manejar errores de tarjetas
resource "aws_lambda_function" "card_error_lambda" {
  filename      = "../card-service/deploy.zip"
  function_name = "${var.project_name}-${var.environment}-card-error"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.handle_card_error"
  runtime       = "python3.9"
  timeout       = 30

  environment {
    variables = {
      CARDS_ERROR_TABLE = aws_dynamodb_table.card_errors_table.name
    }
  }
}