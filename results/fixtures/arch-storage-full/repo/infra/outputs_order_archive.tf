output "order_archive_table_name" {
  description = "The name of the DynamoDB table for order storage."
  value       = module.order_archive_storage.table_name
}

output "order_archive_table_arn" {
  description = "The ARN of the DynamoDB table for order storage."
  value       = module.order_archive_storage.table_arn
}

output "order_archive_ssm_parameter_names" {
  description = "The names of the SSM parameters created for the order archive stack."
  value       = module.order_archive_storage.ssm_parameter_names
}
