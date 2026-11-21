output "delivery_stream_name" {
  description = "Firehose delivery stream name."
  value       = aws_kinesis_firehose_delivery_stream.this.name
}

output "delivery_stream_arn" {
  description = "Firehose delivery stream ARN."
  value       = aws_kinesis_firehose_delivery_stream.this.arn
}

output "role_arn" {
  description = "Firehose role ARN for extra permissions outside this module."
  value       = aws_iam_role.this.arn
}
