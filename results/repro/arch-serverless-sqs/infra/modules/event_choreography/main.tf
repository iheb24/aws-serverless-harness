locals {
  is_queue_pattern = var.pattern != "custom_event_bus"
  is_fanout        = var.pattern == "sns_to_sqs_fanout"
  is_bus           = var.pattern == "custom_event_bus"
  queue_name       = var.fifo_enabled ? "${var.name}.fifo" : var.name
  dlq_name         = var.fifo_enabled ? "${var.name}-dlq.fifo" : "${var.name}-dlq"
}

resource "aws_sqs_queue" "this" {
  count = local.is_queue_pattern ? 1 : 0

  name                        = local.queue_name
  fifo_queue                  = var.fifo_enabled
  content_based_deduplication = var.fifo_enabled ? var.fifo_content_based_deduplication : null
  visibility_timeout_seconds  = var.visibility_timeout_seconds
  sqs_managed_sse_enabled     = var.queue_kms_key_arn == null
  kms_master_key_id           = var.queue_kms_key_arn

  redrive_policy = var.enable_redrive_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.max_receive_count
  }) : null

  tags = var.tags
}

resource "aws_sqs_queue" "dlq" {
  count = local.is_queue_pattern && var.enable_redrive_dlq ? 1 : 0

  name                      = local.dlq_name
  fifo_queue                = var.fifo_enabled
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = var.queue_kms_key_arn == null
  kms_master_key_id         = var.queue_kms_key_arn

  tags = var.tags
}

resource "aws_sns_topic" "this" {
  count = local.is_fanout ? 1 : 0

  name                        = local.queue_name
  fifo_topic                  = var.fifo_enabled
  content_based_deduplication = var.fifo_enabled ? var.fifo_content_based_deduplication : null
  kms_master_key_id           = var.queue_kms_key_arn

  tags = var.tags
}

resource "aws_sns_topic_subscription" "queue" {
  count = local.is_fanout ? 1 : 0

  topic_arn            = aws_sns_topic.this[0].arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.this[0].arn
  raw_message_delivery = true
}

resource "aws_sqs_queue_policy" "fanout" {
  count = local.is_fanout ? 1 : 0

  queue_url = aws_sqs_queue.this[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSNSFanout"
        Effect    = "Allow"
        Principal = { Service = "sns.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.this[0].arn
        Condition = { ArnEquals = { "aws:SourceArn" = aws_sns_topic.this[0].arn } }
      }
    ]
  })
}

resource "aws_cloudwatch_event_bus" "this" {
  count = local.is_bus ? 1 : 0

  name = var.name
  tags = var.tags
}

resource "aws_cloudwatch_event_archive" "this" {
  count = local.is_bus && var.archive_days > 0 ? 1 : 0

  name             = "${var.name}-archive"
  event_source_arn = aws_cloudwatch_event_bus.this[0].arn
  retention_days   = var.archive_days
}
