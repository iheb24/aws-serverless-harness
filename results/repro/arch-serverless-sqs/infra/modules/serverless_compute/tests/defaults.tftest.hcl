mock_provider "aws" {}

variables {
  name             = "order-worker"
  filename         = "dist/order_worker.zip"
  source_code_hash = "aGFzaA=="
  handler          = "order_worker.entrypoint.handler"
}

run "zip_defaults_are_hardened" {
  command = plan

  assert {
    condition     = aws_lambda_function.this.runtime == "python3.13"
    error_message = "runtime defaults to python3.13"
  }

  assert {
    condition     = aws_lambda_function.this.package_type == "Zip"
    error_message = "package_type defaults to Zip"
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.retention_in_days == 30
    error_message = "logs are retained 30 days by default"
  }

  assert {
    condition     = length(aws_sqs_queue.dlq) == 1
    error_message = "a function-level DLQ is created by default"
  }

  assert {
    condition     = length(aws_lambda_event_source_mapping.sqs) == 0
    error_message = "no triggers are wired unless requested"
  }
}

run "image_package_deploys_from_image_uri" {
  command = plan

  variables {
    package_type = "Image"
    image_uri    = "123456789012.dkr.ecr.eu-west-3.amazonaws.com/order-worker:abc123"
  }

  assert {
    condition     = aws_lambda_function.this.image_uri != null
    error_message = "image packages deploy from image_uri"
  }

  assert {
    condition     = aws_lambda_function.this.handler == null
    error_message = "handler is unset for image packages"
  }
}

run "zip_package_requires_filename_and_handler" {
  command = plan

  variables {
    filename         = null
    source_code_hash = null
    handler          = null
  }

  expect_failures = [
    var.filename,
  ]
}

run "sqs_trigger_wires_mapping_and_iam" {
  command = plan

  variables {
    triggers = {
      sqs = {
        queue_arn = "arn:aws:sqs:eu-west-3:123456789012:order-queue"
      }
    }
  }

  assert {
    condition     = length(aws_lambda_event_source_mapping.sqs) == 1
    error_message = "sqs trigger creates one event source mapping"
  }

  assert {
    condition     = length(aws_iam_role_policy.sqs_trigger) == 1
    error_message = "sqs trigger grants the role queue read permissions"
  }

  assert {
    condition     = aws_lambda_event_source_mapping.sqs[0].batch_size == 10
    error_message = "sqs batch size defaults to 10"
  }
}

run "schedule_trigger_creates_scheduler_role" {
  command = plan

  variables {
    triggers = {
      schedule = {
        expression = "rate(5 minutes)"
      }
    }
  }

  assert {
    condition     = length(aws_scheduler_schedule.this) == 1
    error_message = "schedule trigger creates one scheduler schedule"
  }

  assert {
    condition     = length(aws_iam_role.scheduler) == 1
    error_message = "schedule trigger creates a dedicated scheduler role"
  }
}
