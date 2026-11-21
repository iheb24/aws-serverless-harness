output "report_cron_table_name" {
  description = "The name of the DynamoDB table used for heartbeat/reporting state."
  value       = module.heartbeat_store.table_name
}

output "report_executor_function_arn" {
  description = "The ARN of the Lambda function executing the cron report."
  value       = module.report_executor.function_arn
}
