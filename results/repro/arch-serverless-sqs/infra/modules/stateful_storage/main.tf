resource "aws_dynamodb_table" "this" {
  count = var.enable_dynamodb ? 1 : 0

  name                        = "${var.name}-table"
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = var.dynamodb_partition_key.name
  range_key                   = var.dynamodb_sort_key.name
  stream_enabled              = var.enable_streams
  stream_view_type            = var.enable_streams ? "NEW_AND_OLD_IMAGES" : null
  deletion_protection_enabled = var.deletion_protection_enabled

  attribute {
    name = var.dynamodb_partition_key.name
    type = var.dynamodb_partition_key.type
  }

  attribute {
    name = var.dynamodb_sort_key.name
    type = var.dynamodb_sort_key.type
  }

  point_in_time_recovery {
    enabled = var.pitr_enabled
  }

  server_side_encryption {
    enabled = true
  }

  tags = var.tags
}

resource "aws_s3_bucket" "this" {
  count = var.enable_s3_bucket ? 1 : 0

  bucket        = "${var.name}-bucket"
  force_destroy = var.s3_force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_versioning" "this" {
  count = var.enable_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count = var.enable_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    bucket_key_enabled = var.s3_kms_key_arn != null

    apply_server_side_encryption_by_default {
      sse_algorithm     = var.s3_kms_key_arn == null ? "AES256" : "aws:kms"
      kms_master_key_id = var.s3_kms_key_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count = var.enable_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.enable_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_ssm_parameter" "this" {
  for_each = var.ssm_parameters

  name        = each.key
  description = each.value.description
  type        = "String"
  tier        = "Standard"
  value       = each.value.value

  lifecycle {
    ignore_changes = [value]
  }

  tags = var.tags
}
