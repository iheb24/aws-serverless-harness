mock_provider "aws" {}

variables {
  name       = "order-events"
  bucket_arn = "arn:aws:s3:::order-events-bucket"
}

run "defaults_deliver_raw_gzip_to_s3" {
  command = plan

  assert {
    condition     = aws_kinesis_firehose_delivery_stream.this.destination == "extended_s3"
    error_message = "delivery uses extended_s3"
  }

  assert {
    condition     = aws_iam_role_policy.s3_write.name == "order-events-s3-write"
    error_message = "the role gets scoped s3 write permissions"
  }

  assert {
    condition     = length(aws_iam_role_policy.glue_read) == 0
    error_message = "no glue permissions for raw delivery"
  }
}

run "parquet_requires_glue_names" {
  command = plan

  variables {
    destination = "s3_parquet_glue"
  }

  expect_failures = [
    var.destination,
  ]
}

run "parquet_with_glue_creates_conversion" {
  command = plan

  variables {
    destination        = "s3_parquet_glue"
    glue_database_name = "orders"
    glue_table_name    = "order_events"
  }

  assert {
    condition     = length(aws_iam_role_policy.glue_read) == 1
    error_message = "parquet conversion grants glue read permissions"
  }
}
