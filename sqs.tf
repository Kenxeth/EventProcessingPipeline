# Creating SQS Queue
resource "aws_sqs_queue" "terraform_sqs_queue" {
  name                      = "terraform-example-queue"
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10

  tags = {
    Environment = "dev"
  }
    // If message is not processed after 3 attempts, send it to the dead letter queue.
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.terraform_sqs_dead_letter_queue.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "terraform_sqs_dead_letter_queue" {
  name                      = "terraform-example-dead-letter-queue"
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10

  tags = {
    Environment = "dev"
  }
}
// Allow the DLQ to receive messages from the main queue
resource "aws_sqs_queue_redrive_allow_policy" "allow_redrive" {
  queue_url = aws_sqs_queue.terraform_sqs_dead_letter_queue.id
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.terraform_sqs_queue.arn]
  })
}

// Policy for Lambda role to send messages to SQS
resource "aws_iam_role_policy" "lambda_sqs_policy" {
  name = "lambda-sqs-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "sqs:SendMessage"
        ]

        Resource = aws_sqs_queue.terraform_sqs_queue.arn
      }
    ]
  })
}