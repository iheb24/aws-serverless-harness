output "queue_arn" {
  description = "Main queue ARN; null for the custom_event_bus pattern."
  value       = local.is_queue_pattern ? aws_sqs_queue.this[0].arn : null
}

output "queue_url" {
  description = "Main queue URL; null for the custom_event_bus pattern."
  value       = local.is_queue_pattern ? aws_sqs_queue.this[0].url : null
}

output "queue_name" {
  description = "Main queue name; null for the custom_event_bus pattern."
  value       = local.is_queue_pattern ? aws_sqs_queue.this[0].name : null
}

output "dlq_arn" {
  description = "Dead-letter queue ARN; null when redrive is disabled or on bus pattern."
  value       = local.is_queue_pattern && var.enable_redrive_dlq ? aws_sqs_queue.dlq[0].arn : null
}

output "dlq_url" {
  description = "Dead-letter queue URL; null when redrive is disabled or on bus pattern."
  value       = local.is_queue_pattern && var.enable_redrive_dlq ? aws_sqs_queue.dlq[0].url : null
}

output "topic_arn" {
  description = "SNS topic ARN; only set for the sns_to_sqs_fanout pattern."
  value       = local.is_fanout ? aws_sns_topic.this[0].arn : null
}

output "event_bus_arn" {
  description = "EventBridge bus ARN; only set for the custom_event_bus pattern."
  value       = local.is_bus ? aws_cloudwatch_event_bus.this[0].arn : null
}

output "event_bus_name" {
  description = "EventBridge bus name; only set for the custom_event_bus pattern."
  value       = local.is_bus ? aws_cloudwatch_event_bus.this[0].name : null
}
