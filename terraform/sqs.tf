# SQS para creación de tarjetas
resource "aws_sqs_queue" "create_card_queue" {
  name                      = "${var.project_name}-${var.environment}-create-card-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.create_card_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Environment = var.environment
  }
}

# DLQ para creación de tarjetas
resource "aws_sqs_queue" "create_card_dlq" {
  name = "${var.project_name}-${var.environment}-create-card-dlq"
}

# SQS para notificaciones
resource "aws_sqs_queue" "notification_queue" {
  name                      = "${var.project_name}-${var.environment}-notification-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notification_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Environment = var.environment
  }
}

# DLQ para notificaciones
resource "aws_sqs_queue" "notification_dlq" {
  name = "${var.project_name}-${var.environment}-notification-dlq"
}

# Politica para SQS
resource "aws_iam_policy" "sqs_policy" {
  name = "${var.project_name}-${var.environment}-sqs-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [
          aws_sqs_queue.create_card_queue.arn,
          aws_sqs_queue.notification_queue.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sqs_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.sqs_policy.arn
}

# SQS para notificaciones de errores de tarjetas
resource "aws_sqs_queue" "card_error_queue" {
  name                      = "${var.project_name}-${var.environment}-card-error-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.card_error_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Environment = var.environment
  }
}

# DLQ para errores de tarjetas
resource "aws_sqs_queue" "card_error_dlq" {
  name = "${var.project_name}-${var.environment}-card-error-dlq"
}

# SQS para notificaciones de errores
resource "aws_sqs_queue" "notification_error_queue" {
  name                      = "${var.project_name}-${var.environment}-notification-error-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notification_error_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Environment = var.environment
  }
}

# DLQ para errores de notificaciones
resource "aws_sqs_queue" "notification_error_dlq" {
  name = "${var.project_name}-${var.environment}-notification-error-dlq"
}
