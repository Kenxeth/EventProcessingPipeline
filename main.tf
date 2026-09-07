#  Creating AWS API Gateway
resource "aws_apigatewayv2_api" "apiGateway" {
  name          = "example-http-api"
  protocol_type = "HTTP"
}
# Connection between API Gateway and Lambda function. Request comes to this API Gateway, then it is routed to the Lambda function.
resource "aws_apigatewayv2_integration" "example" {
  api_id           = aws_apigatewayv2_api.apiGateway.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.example.invoke_arn // Route to HERE.
  integration_method = "POST"
  payload_format_version = "2.0"
}
# When a request is made to /events, route it to the API Gateway (target)
resource "aws_apigatewayv2_route" "example" {
  api_id    = aws_apigatewayv2_api.apiGateway.id
  route_key = "POST /events"
  target    = "integrations/${aws_apigatewayv2_integration.example.id}"
}
# Setting Environment
resource "aws_apigatewayv2_stage" "example" {
  api_id      = aws_apigatewayv2_api.apiGateway.id
  name        = "$default"
  auto_deploy = true
}
# Permission for API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.apiGateway.execution_arn}/*/POST/events"
}
