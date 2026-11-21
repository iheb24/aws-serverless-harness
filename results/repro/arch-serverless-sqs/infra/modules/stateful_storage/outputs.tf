output "table_name" {
  description = "DynamoDB table name; null when enable_dynamodb is false."
  value       = var.enable_dynamodb ? aws_dynamodb_table.this[0].name : null
}

output "table_arn" {
  description = "DynamoDB table ARN; null when enable_dynamodb is false."
  value       = var.enable_dynamodb ? aws_dynamodb_table.this[0].arn : null
}

output "table_stream_arn" {
  description = "DynamoDB stream ARN; null unless streams are enabled."
  value       = var.enable_dynamodb && var.enable_streams ? aws_dynamodb_table.this[0].stream_arn : null
}

output "bucket_name" {
  description = "S3 bucket name; null when enable_s3_bucket is false."
  value       = var.enable_s3_bucket ? aws_s3_bucket.this[0].bucket : null
}

output "bucket_arn" {
  description = "S3 bucket ARN; null when enable_s3_bucket is false."
  value       = var.enable_s3_bucket ? aws_s3_bucket.this[0].arn : null
}

output "ssm_parameter_names" {
  description = "Map of requested SSM path to created parameter name."
  value       = { for path, parameter in aws_ssm_parameter.this : path => parameter.name }
}
