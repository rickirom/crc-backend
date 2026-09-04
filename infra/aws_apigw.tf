resource "aws_apigatewayv2_api" "api" {
  name          = "visitor-count-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["http://localhost:3000", "https://${var.environment}.riki.sh", "https://riki.sh"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = [ "content-type" ]
  }
}

resource "aws_apigatewayv2_integration" "lambda_views" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.get_views.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "lambda_increment" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.increment.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_views" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /views"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_views.id}"
}

resource "aws_apigatewayv2_route" "increment" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /increment"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_increment.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

# Permissions:
resource "aws_lambda_permission" "api_gw_views" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_views.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gw_increment" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.increment.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}