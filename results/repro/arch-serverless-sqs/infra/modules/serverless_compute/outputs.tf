output "function_name" {
  description = "Deployed Lambda function name."
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "Deployed Lambda function ARN."
  value       = aws_lambda_function.this.arn
}

output "role_arn" {
  description = "Execution role ARN for extra attachments outside this module."
  value       = aws_iam_role.this.arn
}

output "log_group_name" {
  description = "CloudWatch log group receiving function logs."
  value       = aws_cloudwatch_log_group.this.name
}

output "dlq_url" {
  description = "Function-level dead-letter queue URL; null when enable_dlq is false."
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].url : null
}

output "dlq_arn" {
  description = "Function-level dead-letter queue ARN; null when enable_dlq is false."
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].arn : null
}
