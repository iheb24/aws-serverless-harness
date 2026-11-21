resource "aws_ecr_repository" "this" {
  count = var.create_ecr ? 1 : 0

  name                 = var.name
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/batch/${var.name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

data "aws_region" "current" {}

resource "aws_iam_role" "execution" {
  name = "${var.name}-batch-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "execution_secrets" {
  count = length(var.secrets) > 0 ? 1 : 0

  name = "${var.name}-execution-secrets"
  role = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = values(var.secrets)
      }
    ]
  })
}

resource "aws_iam_role" "job" {
  name = "${var.name}-batch-job-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "job_app" {
  count = length(var.policy_statements) > 0 ? 1 : 0

  name = "${var.name}-job-app"
  role = aws_iam_role.job.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for statement in var.policy_statements : {
        Effect   = "Allow"
        Action   = statement.actions
        Resource = statement.resources
      }
    ]
  })
}

resource "aws_batch_compute_environment" "this" {
  name = "${var.name}-compute"
  type = "MANAGED"

  compute_resources {
    type               = var.compute_type
    max_vcpus          = 16
    subnets            = var.subnet_ids
    security_group_ids = var.security_group_ids
  }
}

resource "aws_batch_job_queue" "this" {
  name     = "${var.name}-queue"
  state    = "ENABLED"
  priority = 1

  compute_environment_order {
    order               = 0
    compute_environment = aws_batch_compute_environment.this.arn
  }
}

resource "aws_batch_job_definition" "this" {
  name = var.name
  type = "container"

  platform_capabilities = ["FARGATE"]

  retry_strategy {
    attempts = var.retry_attempts
  }

  timeout {
    attempt_duration_seconds = var.timeout_seconds
  }

  container_properties = jsonencode({
    image = var.image_uri
    resourceRequirements = [
      { type = "VCPU", value = tostring(var.vcpus) },
      { type = "MEMORY", value = tostring(var.memory) },
    ]
    command          = var.command
    environment      = [for key, value in var.environment : { name = key, value = value }]
    secrets          = [for key, arn in var.secrets : { name = key, valueFrom = arn }]
    executionRoleArn = aws_iam_role.execution.arn
    jobRoleArn       = aws_iam_role.job.arn
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.this.name
        "awslogs-region"        = data.aws_region.current.region
        "awslogs-stream-prefix" = var.name
      }
    }
  })

  tags = var.tags
}

resource "aws_iam_role" "scheduler" {
  count = var.trigger_schedule != null ? 1 : 0

  name = "${var.name}-batch-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "scheduler.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "scheduler" {
  count = var.trigger_schedule != null ? 1 : 0

  name = "${var.name}-batch-scheduler"
  role = aws_iam_role.scheduler[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["batch:SubmitJob"]
        Resource = [aws_batch_job_queue.this.arn, aws_batch_job_definition.this.arn]
      }
    ]
  })
}

resource "aws_scheduler_schedule" "this" {
  count = var.trigger_schedule != null ? 1 : 0

  name                = "${var.name}-schedule"
  schedule_expression = var.trigger_schedule

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:batch:submitJob"
    role_arn = aws_iam_role.scheduler[0].arn

    input = jsonencode({
      JobName       = var.name
      JobQueue      = aws_batch_job_queue.this.arn
      JobDefinition = aws_batch_job_definition.this.arn
    })
  }
}
