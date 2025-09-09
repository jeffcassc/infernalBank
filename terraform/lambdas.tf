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