locals {
  is_parquet = var.destination == "s3_parquet_glue"
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/kinesisfirehose/${var.name}"
  retention_in_days = 30
  tags              = var.tags
}

resource "aws_cloudwatch_log_stream" "delivery" {
  name           = "S3Delivery"
  log_group_name = aws_cloudwatch_log_group.this.name
}

resource "aws_iam_role" "this" {
  name = "${var.name}-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "firehose.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "s3_write" {
  name = "${var.name}-s3-write"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucketMultipartUploads",
          "s3:AbortMultipartUpload",
          "s3:ListBucket",
        ]
        Resource = [var.bucket_arn, "${var.bucket_arn}/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy" "glue_read" {
  count = local.is_parquet ? 1 : 0

  name = "${var.name}-glue-read"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:GetTable",
          "glue:GetTableVersion",
          "glue:GetTableVersions",
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_transform" {
  count = var.enable_lambda_transform && var.transform_lambda_arn != null ? 1 : 0

  name = "${var.name}-lambda-transform"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction", "lambda:GetFunctionConfiguration"]
        Resource = [var.transform_lambda_arn]
      }
    ]
  })
}

resource "aws_kinesis_firehose_delivery_stream" "this" {
  name        = var.name
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.this.arn
    bucket_arn          = var.bucket_arn
    prefix              = var.prefix
    error_output_prefix = var.error_prefix
    compression_format  = var.compression

    buffering_size     = var.buffering_size_mb
    buffering_interval = var.buffering_interval_seconds

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.this.name
      log_stream_name = aws_cloudwatch_log_stream.delivery.name
    }

    dynamic "processing_configuration" {
      for_each = var.enable_lambda_transform && var.transform_lambda_arn != null ? [1] : []
      content {
        enabled = true
        processors {
          type = "Lambda"
          parameters {
            parameter_name  = "LambdaArn"
            parameter_value = var.transform_lambda_arn
          }
        }
      }
    }

    dynamic "data_format_conversion_configuration" {
      for_each = local.is_parquet ? [1] : []
      content {
        input_format_configuration {
          deserializer {
            open_x_json_ser_de {}
          }
        }
        output_format_configuration {
          serializer {
            parquet_ser_de {}
          }
        }
        schema_configuration {
          database_name = var.glue_database_name
          table_name    = var.glue_table_name
          role_arn      = aws_iam_role.this.arn
        }
      }
    }
  }

  tags = var.tags
}
