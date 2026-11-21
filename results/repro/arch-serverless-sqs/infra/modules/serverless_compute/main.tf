locals {
  is_zip      = var.package_type == "Zip"
  vpc_enabled = length(var.vpc_subnet_ids) > 0
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = var.tags
}

resource "aws_iam_role" "this" {
  name = "${var.name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "logging" {
  name = "${var.name}-logging"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = ["${aws_cloudwatch_log_group.this.arn}:*"]
      }
    ]
  })
}

resource "aws_iam_role_policy" "app" {
  count = length(var.policy_statements) > 0 ? 1 : 0

  name = "${var.name}-app"
  role = aws_iam_role.this.id

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

resource "aws_iam_role_policy" "sqs_trigger" {
  count = var.triggers.sqs != null ? 1 : 0

  name = "${var.name}-sqs-trigger"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
        ]
        Resource = [var.triggers.sqs.queue_arn]
      }
    ]
  })
}

resource "aws_iam_role_policy" "stream_trigger" {
  count = var.triggers.dynamodb_stream != null ? 1 : 0

  name = "${var.name}-stream-trigger"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeStream",
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:ListStreams",
        ]
        Resource = [var.triggers.dynamodb_stream.stream_arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "vpc" {
  count = local.vpc_enabled ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_sqs_queue" "dlq" {
  count = var.enable_dlq ? 1 : 0

  name                      = "${var.name}-dlq"
  message_retention_seconds = var.dlq_message_retention_seconds
  sqs_managed_sse_enabled   = var.kms_key_arn == null
  kms_master_key_id         = var.kms_key_arn
  tags                      = var.tags
}

resource "aws_iam_role_policy" "dlq" {
  count = var.enable_dlq ? 1 : 0

  name = "${var.name}-dlq"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = aws_sqs_queue.dlq[0].arn
      }
    ]
  })
}

resource "aws_lambda_function" "this" {
  function_name    = var.name
  package_type     = var.package_type
  filename         = local.is_zip ? var.filename : null
  source_code_hash = local.is_zip ? var.source_code_hash : null
  image_uri        = local.is_zip ? null : var.image_uri
  handler          = local.is_zip ? var.handler : null
  runtime          = local.is_zip ? var.runtime : null
  role             = aws_iam_role.this.arn
  memory_size      = var.memory_size
  timeout          = var.timeout
  kms_key_arn      = var.kms_key_arn

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  dynamic "dead_letter_config" {
    for_each = var.enable_dlq ? [1] : []
    content {
      target_arn = aws_sqs_queue.dlq[0].arn
    }
  }

  dynamic "vpc_config" {
    for_each = local.vpc_enabled ? [1] : []
    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }

  tags = var.tags

  depends_on = [aws_cloudwatch_log_group.this]
}

resource "aws_lambda_event_source_mapping" "sqs" {
  count = var.triggers.sqs != null ? 1 : 0

  event_source_arn                   = var.triggers.sqs.queue_arn
  function_name                      = aws_lambda_function.this.arn
  batch_size                         = var.triggers.sqs.batch_size
  maximum_batching_window_in_seconds = var.triggers.sqs.maximum_batching_window_seconds
}

resource "aws_lambda_event_source_mapping" "stream" {
  count = var.triggers.dynamodb_stream != null ? 1 : 0

  event_source_arn  = var.triggers.dynamodb_stream.stream_arn
  function_name     = aws_lambda_function.this.arn
  batch_size        = var.triggers.dynamodb_stream.batch_size
  starting_position = var.triggers.dynamodb_stream.starting_position
}

resource "aws_sns_topic_subscription" "this" {
  count = var.triggers.sns != null ? 1 : 0

  topic_arn = var.triggers.sns.topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.this.arn
}

resource "aws_lambda_permission" "sns" {
  count = var.triggers.sns != null ? 1 : 0

  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.triggers.sns.topic_arn
}

resource "aws_lambda_permission" "eventbridge" {
  count = var.triggers.eventbridge != null ? 1 : 0

  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = var.triggers.eventbridge.rule_arn
}

resource "aws_iam_role" "scheduler" {
  count = var.triggers.schedule != null ? 1 : 0

  name = "${var.name}-scheduler-role"

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
  count = var.triggers.schedule != null ? 1 : 0

  name = "${var.name}-scheduler"
  role = aws_iam_role.scheduler[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = [aws_lambda_function.this.arn]
      }
    ]
  })
}

resource "aws_scheduler_schedule" "this" {
  count = var.triggers.schedule != null ? 1 : 0

  name                = "${var.name}-schedule"
  schedule_expression = var.triggers.schedule.expression

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.this.arn
    role_arn = aws_iam_role.scheduler[0].arn
  }
}

resource "aws_lambda_permission" "s3" {
  count = var.triggers.s3 != null ? 1 : 0

  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.triggers.s3.bucket_arn
}

resource "aws_s3_bucket_notification" "this" {
  count = var.triggers.s3 != null ? 1 : 0

  bucket = var.triggers.s3.bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.this.arn
    events              = var.triggers.s3.events
    filter_prefix       = var.triggers.s3.filter_prefix
    filter_suffix       = var.triggers.s3.filter_suffix
  }

  depends_on = [aws_lambda_permission.s3]
}
