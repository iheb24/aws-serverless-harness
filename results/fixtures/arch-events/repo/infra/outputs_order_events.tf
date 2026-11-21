output "orders_bus_arn" {
  description = "The ARN of the EventBridge bus for order events."
  value       = module.orders_bus.event_bus_arn
}

output "orders_topic_arn" {
  description = "The ARN of the SNS topic for fanout order events."
  value       = module.orders_topic.topic_arn
}

output "fulfillment_queue_url" {
  description = "The URL of the fulfillment SQS queue."
  value       = module.fulfillment_queue.queue_url
}

output "inventory_queue_url" {
  description = "The URL of the inventory SQS queue."
  value       = module.inventory_queue.queue_url
}
