# Bucket para plantillas de email
resource "aws_s3_bucket" "email_templates_bucket" {
  bucket = "${var.project_name}-${var.environment}-email-templates"
  
  tags = {
    Environment = var.environment
  }
}

# Lambda para notificaciones
resource "aws_lambda_function" "notification_lambda" {
  filename      = "../notification-service/deploy.zip"
  function_name = "${var.project_name}-${var.environment}-notification"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.send_notification"
  runtime       = "python3.9"

  environment {
    variables = {
      TEMPLATES_BUCKET = aws_s3_bucket.email_templates_bucket.bucket
      SES_EMAIL        = "notifications@inferno-bank.com"
    }
  }
}

# Trigger para notificaciones
resource "aws_lambda_event_source_mapping" "notification_trigger" {
  event_source_arn = aws_sqs_queue.notification_queue.arn
  function_name    = aws_lambda_function.notification_lambda.arn
  batch_size       = 1
}

# Lambda para manejar errores de notificaciones
resource "aws_lambda_function" "notification_error_lambda" {
  filename      = "../notification-service/deploy.zip"
  function_name = "${var.project_name}-${var.environment}-notification-error"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.handle_notification_error"
  runtime       = "python3.9"

  environment {
    variables = {
      NOTIFICATION_ERRORS_TABLE = aws_dynamodb_table.notification_errors_table.name
    }
  }
}

# Trigger para errores de notificaciones
resource "aws_lambda_event_source_mapping" "notification_error_trigger" {
  event_source_arn = aws_sqs_queue.notification_error_queue.arn
  function_name    = aws_lambda_function.notification_error_lambda.arn
  batch_size       = 1
}

# Bucket para reportes de transacciones
resource "aws_s3_bucket" "transactions_reports_bucket" {
  bucket = "${var.project_name}-${var.environment}-reports"
  
  tags = {
    Environment = var.environment
  }
}

