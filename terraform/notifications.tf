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