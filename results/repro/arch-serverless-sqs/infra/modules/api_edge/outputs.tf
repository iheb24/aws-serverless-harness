output "api_endpoint" {
  description = "Invoke URL of the API (includes the stage when not $default)."
  value       = aws_apigatewayv2_stage.this.invoke_url
}

output "api_id" {
  description = "API Gateway v2 API id."
  value       = aws_apigatewayv2_api.this.id
}

output "api_arn" {
  description = "API ARN for policies and WAF attachments."
  value       = aws_apigatewayv2_api.this.arn
}

output "execution_arn" {
  description = "Execution ARN used for scoping invoke permissions."
  value       = aws_apigatewayv2_api.this.execution_arn
}
