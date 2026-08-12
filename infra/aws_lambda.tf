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

resource "aws_iam_role" "lambda_exec" {
  name               = "visitor-count-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "dynamodb_read" {
  statement {
    actions   = ["dynamodb:GetItem"]
    resources = [aws_dynamodb_table.vctable.arn] # or a data source if table already exists
  }
}

resource "aws_iam_role_policy" "dynamodb_read" {
  name   = "visitor-count-dynamodb-read"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.dynamodb_read.json
}

# Package the Lambda function code
data "archive_file" "get_views" {
  type        = "zip"
  source_file = "${path.module}/../app/src/get_views.py"
  output_path = "${path.module}/lambda/get_views.zip"
}

# Lambda function
resource "aws_lambda_function" "get_views" {
  filename      = data.archive_file.get_views.output_path
  function_name = "crc-visitor-count-get"
  role          = aws_iam_role.lambda_exec.arn
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