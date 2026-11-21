mock_provider "aws" {}

variables {
  name      = "order-worker"
  image_uri = "123456789012.dkr.ecr.eu-west-3.amazonaws.com/order-worker:latest"
  queue_arn = "arn:aws:sqs:eu-west-3:123456789012:orders"
}

run "defaults_create_cluster_ecr_and_worker_service" {
  command = plan

  assert {
    condition     = length(aws_ecr_repository.this) == 1
    error_message = "the ECR repository is created by default"
  }

  assert {
    condition     = length(aws_ecs_service.this) == 1
    error_message = "worker mode runs an ECS service"
  }

  assert {
    condition     = length(aws_appautoscaling_target.this) == 1
    error_message = "worker mode wires queue-depth autoscaling"
  }

  assert {
    condition     = length(aws_scheduler_schedule.this) == 0
    error_message = "no schedule without scheduled_task mode"
  }
}

run "scheduled_task_creates_scheduler_and_no_service" {
  command = plan

  variables {
    execution_mode      = "scheduled_task"
    schedule_expression = "rate(1 hour)"
  }

  assert {
    condition     = length(aws_scheduler_schedule.this) == 1
    error_message = "scheduled mode creates the schedule"
  }

  assert {
    condition     = length(aws_ecs_service.this) == 0
    error_message = "scheduled mode creates no long-running service"
  }
}

run "worker_mode_requires_queue" {
  command = plan

  variables {
    queue_arn = null
  }

  expect_failures = [
    var.execution_mode,
  ]
}
