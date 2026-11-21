output "orders_queue_url" {
  description = "The URL of the SQS queue for order processing."
  value       = module.orders_queue.queue_url
}

output "orders_table_name" {
  description = "The name of the DynamoDB table storing order records."
  value       = module.orders_table.table_name
}

output "orders_worker_function_arn" {
  description = "The ARN of the order worker Lambda function."
  value       = module.orders_worker_lambda.function_arn
}
