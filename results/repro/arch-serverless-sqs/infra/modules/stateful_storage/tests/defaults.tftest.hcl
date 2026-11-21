mock_provider "aws" {}

variables {
  name = "orders-store"
}

run "dynamodb_defaults_are_hardened" {
  command = plan

  assert {
    condition     = aws_dynamodb_table.this[0].billing_mode == "PAY_PER_REQUEST"
    error_message = "billing defaults to on-demand"
  }

  assert {
    condition     = aws_dynamodb_table.this[0].point_in_time_recovery[0].enabled == true
    error_message = "point-in-time recovery is on by default"
  }

  assert {
    condition     = aws_dynamodb_table.this[0].server_side_encryption[0].enabled == true
    error_message = "encryption at rest is on by default"
  }

  assert {
    condition     = length(aws_s3_bucket.this) == 0 && length(aws_ssm_parameter.this) == 0
    error_message = "only the table is provisioned by default"
  }
}

run "s3_bucket_is_hardened" {
  command = plan

  variables {
    enable_s3_bucket = true
  }

  assert {
    condition     = aws_s3_bucket_versioning.this[0].versioning_configuration[0].status == "Enabled"
    error_message = "bucket versioning is always enabled"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this[0].block_public_policy == true
    error_message = "public access is fully blocked"
  }

  assert {
    condition     = length(aws_s3_bucket_server_side_encryption_configuration.this) == 1
    error_message = "default encryption is always configured"
  }
}

run "ssm_parameters_are_created_as_placeholders" {
  command = plan

  variables {
    ssm_parameters = {
      "/dev/order-ingestion/orders_table" = {
        value       = "unset"
        description = "DynamoDB table name for the order worker."
      }
    }
  }

  assert {
    condition     = length(aws_ssm_parameter.this) == 1
    error_message = "each requested parameter is created"
  }

  assert {
    condition     = aws_ssm_parameter.this["/dev/order-ingestion/orders_table"].type == "String"
    error_message = "placeholders use the String type"
  }
}

run "module_requires_at_least_one_resource" {
  command = plan

  variables {
    enable_dynamodb  = false
    enable_s3_bucket = false
  }

  expect_failures = [
    var.name,
  ]
}
