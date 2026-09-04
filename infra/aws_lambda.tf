# a lambda function that executes the lookup and update of the table
# permissions for the lambda to access dynamodb
# api gateway to invoke the lambda
# permissions for the apigw to invoke lambda

##################
#   Lambda IAM   #
##################
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_read_dynamo" {
  name               = "get-visitor-count-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "lambda_increment_dynamo" {
  name               = "increment-visitor-count-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs_read" {
  role       = aws_iam_role.lambda_read_dynamo.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_logs_increment" {
  role       = aws_iam_role.lambda_increment_dynamo.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "dynamodb_read" {
  statement {
    actions   = ["dynamodb:GetItem"]
    resources = [aws_dynamodb_table.vctable.arn] # or a data source if table already exists
  }
}

data "aws_iam_policy_document" "dynamodb_increment" {
  statement {
    actions   = ["dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.vctable.arn]
  }
}

resource "aws_iam_role_policy" "dynamodb_read" {
  name   = "visitor-count-dynamodb-read"
  role   = aws_iam_role.lambda_read_dynamo.id
  policy = data.aws_iam_policy_document.dynamodb_read.json
}

resource "aws_iam_role_policy" "dynamodb_increment" {
  name   = "visitor-count-dynamodb-increment"
  role   = aws_iam_role.lambda_increment_dynamo.id
  policy = data.aws_iam_policy_document.dynamodb_increment.json
}

# Idea for RFC (TO DO):
locals {
  lambdas = ["get-views", "increment"]
}

# Package the Lambda function code
data "archive_file" "get_views" {
  type        = "zip"
  source_file = "${path.module}/../app/src/get_views.py"
  output_path = "${path.module}/lambda/get_views.zip"
}

data "archive_file" "increment" {
  type        = "zip"
  source_file = "${path.module}/../app/src/increment.py"
  output_path = "${path.module}/lambda/increment.zip"
}

# Lambda functions
# get views
resource "aws_lambda_function" "get_views" {
  filename      = data.archive_file.get_views.output_path
  function_name = "crc-visitor-count-get"
  role          = aws_iam_role.lambda_read_dynamo.arn
  handler       = "get_views.handler"
  code_sha256   = data.archive_file.get_views.output_base64sha256

  runtime = "python3.14"

  environment {
    variables = {
      TABLE_NAME = "VisitorCount"
    }
  }

  tags = {
    Environment = var.environment
    Application = "CRC"
  }
}

#increment views
resource "aws_lambda_function" "increment" {
  filename      = data.archive_file.increment.output_path
  function_name = "crc-visitor-increment"
  role          = aws_iam_role.lambda_increment_dynamo.arn
  handler       = "increment.handler"
  code_sha256   = data.archive_file.increment.output_base64sha256

  runtime = "python3.14"

  environment {
    variables = {
      TABLE_NAME = "VisitorCount"
    }
  }

  tags = {
    Environment = var.environment
    Application = "CRC"
  }
}