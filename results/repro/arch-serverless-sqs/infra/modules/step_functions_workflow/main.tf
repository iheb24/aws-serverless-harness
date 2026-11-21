resource "aws_cloudwatch_log_group" "this" {
  count = var.log_level != "OFF" ? 1 : 0

  name              = "/aws/vendedlogs/states/${var.name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_iam_role" "this" {
  name = "${var.name}-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "states.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "invoke_lambdas" {
  count = length(var.task_lambda_arns) > 0 ? 1 : 0

  name = "${var.name}-invoke-lambdas"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = values(var.task_lambda_arns)
      }
    ]
  })
}

resource "aws_iam_role_policy" "logging" {
  count = var.log_level != "OFF" ? 1 : 0

  name = "${var.name}-logging"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
        ]
        Resource = ["${aws_cloudwatch_log_group.this[0].arn}:*"]
      }
    ]
  })
}

resource "aws_sfn_state_machine" "this" {
  name       = var.name
  type       = var.workflow_type
  role_arn   = aws_iam_role.this.arn
  definition = var.asl_definition

  dynamic "logging_configuration" {
    for_each = var.log_level != "OFF" ? [1] : []
    content {
      level                  = var.log_level
      include_execution_data = var.log_level == "ALL"
      log_destination        = "${aws_cloudwatch_log_group.this[0].arn}:*"
    }
  }

  tracing_configuration {
    enabled = var.enable_xray
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy.invoke_lambdas,
    aws_iam_role_policy.logging,
  ]
}
