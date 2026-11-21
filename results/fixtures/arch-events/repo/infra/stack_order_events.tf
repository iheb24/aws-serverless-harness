module "orders_bus" {
  source = "./modules/event_choreography"

  name         = "order-events-bus"
  pattern      = "custom_event_bus"
  archive_days = 90

  tags = local.common_tags
}

module "orders_topic" {
  source = "./modules/event_choreography"

  name    = "order-events-topic"
  pattern = "sns_to_sqs_fanout"

  tags = local.common_tags
}

module "fulfillment_queue" {
  source = "./modules/event_choreography"

  name               = "fulfillment-queue"
  pattern            = "sqs_queue"
  enable_redrive_dlq = true

  tags = local.common_tags
}

module "inventory_queue" {
  source = "./modules/event_choreography"

  name               = "inventory-queue"
  pattern            = "sqs_queue"
  enable_redrive_dlq = true

  tags = local.common_tags
}
