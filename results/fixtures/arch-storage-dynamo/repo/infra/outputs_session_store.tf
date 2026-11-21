output "session_store_table_name" {
  description = "The name of the DynamoDB table for session storage."
  value       = module.session_store.table_name
}

output "session_store_table_arn" {
  description = "The ARN of the DynamoDB table for session storage."
  value       = module.session_store.table_arn
}

output "session_store_ssm_parameter_names" {
  description = "The names of the SSM parameters created for the session store."
  value       = module.session_store.ssm_parameter_names
}
