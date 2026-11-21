mock_provider "aws" {}

variables {
  name       = "order-archive"
  image_uri  = "123456789012.dkr.ecr.eu-west-3.amazonaws.com/order-archive:latest"
  subnet_ids = ["subnet-0123456789abcdef0"]
}

run "defaults_create_queue_definition_and_ecr" {
  command = plan

  assert {
    condition     = aws_batch_compute_environment.this.compute_resources[0].type == "FARGATE"
    error_message = "compute defaults to on-demand Fargate"
  }

  assert {
    condition     = aws_batch_job_definition.this.retry_strategy[0].attempts == 2
    error_message = "jobs retry twice by default"
  }

  assert {
    condition     = length(aws_ecr_repository.this) == 1
    error_message = "the ECR repository is created by default"
  }

  assert {
    condition     = length(aws_scheduler_schedule.this) == 0
    error_message = "no scheduler without a trigger expression"
  }
}

run "spot_and_schedule_switches_apply" {
  command = plan

  variables {
    compute_type     = "FARGATE_SPOT"
    trigger_schedule = "rate(1 day)"
  }

  assert {
    condition     = aws_batch_compute_environment.this.compute_resources[0].type == "FARGATE_SPOT"
    error_message = "spot capacity is a flag"
  }

  assert {
    condition     = length(aws_scheduler_schedule.this) == 1
    error_message = "a trigger expression creates the scheduler target"
  }
}

run "invalid_compute_type_is_rejected" {
  command = plan

  variables {
    compute_type = "EC2"
  }

  expect_failures = [
    var.compute_type,
  ]
}
