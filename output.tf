output "api_gateway_url" {
  value = aws_apigatewayv2_api.apiGateway.api_endpoint
}

output "sqs_queue_url" {
  value = aws_sqs_queue.terraform_sqs_queue.id
}