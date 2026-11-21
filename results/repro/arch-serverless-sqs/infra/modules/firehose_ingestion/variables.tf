variable "name" {
  type        = string
  description = "Delivery stream name; prefixes its role and log group."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,60}$", var.name))
    error_message = "name must be kebab-case, 2-61 characters."
  }
}

variable "bucket_arn" {
  type        = string
  description = "ARN of the destination S3 bucket (from stateful_storage)."
}

variable "destination" {
  type        = string
  description = "s3_raw for raw delivery; s3_parquet_glue adds Parquet conversion via Glue."
  default     = "s3_raw"

  validation {
    condition     = contains(["s3_raw", "s3_parquet_glue"], var.destination)
    error_message = "destination must be s3_raw or s3_parquet_glue."
  }

  validation {
    condition = var.destination != "s3_parquet_glue" || (
      var.glue_database_name != null && var.glue_table_name != null
    )
    error_message = "s3_parquet_glue requires glue_database_name and glue_table_name."
  }
}

variable "glue_database_name" {
  type        = string
  description = "Glue database for Parquet schema conversion."
  default     = null
}

variable "glue_table_name" {
  type        = string
  description = "Glue table for Parquet schema conversion."
  default     = null
}

variable "buffering_size_mb" {
  type        = number
  description = "Buffer size before delivery, in MB (1-128)."
  default     = 5

  validation {
    condition     = var.buffering_size_mb >= 1 && var.buffering_size_mb <= 128
    error_message = "buffering_size_mb must be between 1 and 128."
  }
}

variable "buffering_interval_seconds" {
  type        = number
  description = "Buffer interval before delivery, in seconds (60-900)."
  default     = 300

  validation {
    condition     = var.buffering_interval_seconds >= 60 && var.buffering_interval_seconds <= 900
    error_message = "buffering_interval_seconds must be between 60 and 900."
  }
}

variable "compression" {
  type        = string
  description = "Compression for delivered objects."
  default     = "GZIP"

  validation {
    condition     = contains(["UNCOMPRESSED", "GZIP", "ZIP", "Snappy", "HADOOP_SNAPPY"], var.compression)
    error_message = "unsupported compression value."
  }
}

variable "enable_lambda_transform" {
  type        = bool
  description = "Run an inline Lambda record transformation before delivery."
  default     = false
}

variable "transform_lambda_arn" {
  type        = string
  description = "ARN of the transformation Lambda when enable_lambda_transform is true."
  default     = null
}

variable "prefix" {
  type        = string
  description = "S3 key prefix for delivered records."
  default     = "raw/"
}

variable "error_prefix" {
  type        = string
  description = "S3 key prefix for failed records."
  default     = "errors/"
}

variable "tags" {
  type        = map(string)
  description = "Extra tags merged onto every taggable resource."
  default     = {}
}
