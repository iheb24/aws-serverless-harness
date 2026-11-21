mock_provider "aws" {}

variables {
  name = "order-events"
}

run "queue_pattern_defaults_to_redrive_dlq" {
  command = plan

  assert {
    condition     = length(aws_sqs_queue.this) == 1
    error_message = "default pattern creates the main queue"
  }

  assert {
    condition     = length(aws_sqs_queue.dlq) == 1
    error_message = "redrive DLQ is created by default"
  }

  assert {
    condition     = length(aws_sns_topic.this) == 0 && length(aws_cloudwatch_event_bus.this) == 0
    error_message = "no topic or bus is created for the queue pattern"
  }

  assert {
    condition     = aws_sqs_queue.this[0].sqs_managed_sse_enabled == true
    error_message = "aws-managed SSE is the default encryption"
  }
}

run "fifo_pattern_suffixes_names" {
  command = plan

  variables {
    fifo_enabled = true
  }

  assert {
    condition     = aws_sqs_queue.this[0].name == "order-events.fifo"
    error_message = "fifo queues carry the .fifo suffix"
  }

  assert {
    condition     = aws_sqs_queue.dlq[0].name == "order-events-dlq.fifo"
    error_message = "fifo DLQs carry the .fifo suffix"
  }
}

run "fanout_creates_topic_subscription_and_policy" {
  command = plan

  variables {
    pattern = "sns_to_sqs_fanout"
  }

  assert {
    condition     = length(aws_sns_topic.this) == 1
    error_message = "fanout creates the SNS topic"
  }

  assert {
    condition     = length(aws_sns_topic_subscription.queue) == 1
    error_message = "fanout subscribes the queue to the topic"
  }

  assert {
    condition     = length(aws_sqs_queue_policy.fanout) == 1
    error_message = "fanout scopes the queue policy to the topic ARN"
  }
}

run "bus_pattern_creates_bus_and_optional_archive" {
  command = plan

  variables {
    pattern      = "custom_event_bus"
    archive_days = 14
  }

  assert {
    condition     = length(aws_cloudwatch_event_bus.this) == 1
    error_message = "bus pattern creates the custom event bus"
  }

  assert {
    condition     = length(aws_sqs_queue.this) == 0
    error_message = "bus pattern creates no queue"
  }

  assert {
    condition     = length(aws_cloudwatch_event_archive.this) == 1
    error_message = "archive is created when archive_days is positive"
  }
}

run "invalid_pattern_is_rejected" {
  command = plan

  variables {
    pattern = "kinesis"
  }

  expect_failures = [
    var.pattern,
  ]
}
