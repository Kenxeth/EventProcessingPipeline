#   *** Policies and roles for Lambda functions ***
# ----------------------------------------------------

# Policy for Lambda execution
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
# Setting policy inside a new iam role
resource "aws_iam_role" "lambda_execution_role" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Letting this role execute Lambda functions
resource "aws_iam_role_policy_attachment" "example" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Letting this role read messages from the SQS queue
resource "aws_iam_role_policy_attachment" "worker_sqs_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

# Letting this role read and write to DynamoDB table.
data "aws_iam_policy_document" "lambda_dynamodb" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem"
    ]

    resources = [
      aws_dynamodb_table.userid-eventid-table.arn
    ]
  }
}

resource "aws_iam_policy" "lambda_dynamodb" {
  name   = "lambda-dynamodb-policy"
  policy = data.aws_iam_policy_document.lambda_dynamodb.json
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb.arn
}
#  *** Turning function code into zip files. ***
# ----------------------------------------------------

# Package the Lambda function code. HTTP -> Lambda function
data "archive_file" "example" {
  type        = "zip"
  source_file = "${path.module}/dist/index.js"
  output_path = "${path.module}/lambda/function.zip"
}

data "archive_file" "sqs_to_lambda" {
  type        = "zip"
  source_file = "${path.module}/dist/index.js"
  output_path = "${path.module}/lambda/sqs_to_lambda.zip"
}

# *** Lambda Functions **
# ----------------------------------------------------


# Lambda function from SQS -> Lambda function
resource "aws_lambda_function" "sqs_to_lambda_worker" {
  filename      = data.archive_file.sqs_to_lambda.output_path
  function_name = "sqs_to_lambda_worker"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "index.SQSToLambdaHandler"
  code_sha256   = data.archive_file.sqs_to_lambda.output_base64sha256

  runtime = "nodejs24.x"

  environment {
    variables = {
      ENVIRONMENT = "production"
      LOG_LEVEL   = "info"
      QUEUE_URL = aws_sqs_queue.terraform_sqs_queue.url
      DYNAMODB_TABLE_ARN = aws_dynamodb_table.userid-eventid-table.arn
    }
  }

  tags = {
    Environment = "production"
    Application = "example"
  }
}


# Lambda function from HTTP -> Lambda function
resource "aws_lambda_function" "example" {
  filename      = data.archive_file.example.output_path
  function_name = "lambda_function"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "index.handler"
  code_sha256   = data.archive_file.example.output_base64sha256

  runtime = "nodejs24.x"

  environment {
    variables = {
      ENVIRONMENT = "production"
      LOG_LEVEL   = "info"
      QUEUE_URL = aws_sqs_queue.terraform_sqs_queue.url
      DYNAMODB_TABLE_ARN = aws_dynamodb_table.userid-eventid-table.arn
    }
  }

  tags = {
    Environment = "production"
    Application = "example"
  }
}

# *** SQS ****
# ----------------------------------------------------

resource "aws_lambda_event_source_mapping" "sqs_to_worker" {
  event_source_arn = aws_sqs_queue.terraform_sqs_queue.arn // Queue
  function_name    = aws_lambda_function.sqs_to_lambda_worker.arn // Trigger this lambda function when a message is sent to the SQS queue above.
  batch_size = 10
}



