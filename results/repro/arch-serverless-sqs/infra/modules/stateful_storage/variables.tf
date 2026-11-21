variable "name" {
  type        = string
  description = "Base name for the table, bucket, and parameter namespace."

  validation {
    condition = can(regex("^[a-z][a-z0-9-]{1,60}$", var.name)) && (
      var.enable_dynamodb || var.enable_s3_bucket || length(var.ssm_parameters) > 0
    )
    error_message = "name must be kebab-case and at least one of enable_dynamodb, enable_s3_bucket, ssm_parameters must be set."
  }
}

variable "enable_dynamodb" {
  type        = bool
  description = "Provision the DynamoDB table."
  default     = true
}

variable "dynamodb_partition_key" {
  type = object({
    name = string
    type = string
  })
  description = "Partition key attribute; type is one of S, N, B."
  default     = { name = "pk", type = "S" }

  validation {
    condition     = contains(["S", "N", "B"], var.dynamodb_partition_key.type)
    error_message = "partition key type must be S, N, or B."
  }
}

variable "dynamodb_sort_key" {
  type = object({
    name = string
    type = string
  })
  description = "Sort key attribute; type is one of S, N, B."
  default     = { name = "sk", type = "S" }

  validation {
    condition     = contains(["S", "N", "B"], var.dynamodb_sort_key.type)
    error_message = "sort key type must be S, N, or B."
  }
}

variable "enable_streams" {
  type        = bool
  description = "Enable DynamoDB streams (NEW_AND_OLD_IMAGES) for CDC consumers."
  default     = false
}

variable "pitr_enabled" {
  type        = bool
  description = "Point-in-time recovery for the table; disabling is a prod blocker."
  default     = true
}

variable "deletion_protection_enabled" {
  type        = bool
  description = "Deletion protection for the table; enable for staging and prod."
  default     = false
}

variable "enable_s3_bucket" {
  type        = bool
  description = "Provision the hardened S3 bucket."
  default     = false
}

variable "s3_force_destroy" {
  type        = bool
  description = "Allow Terraform to delete a non-empty bucket; dev convenience only."
  default     = false
}

variable "s3_kms_key_arn" {
  type        = string
  description = "Customer-managed CMK for bucket encryption; AES256 when null."
  default     = null
}

variable "ssm_parameters" {
  type = map(object({
    value       = string
    description = string
  }))
  description = "SSM parameters created as placeholders; workloads overwrite values at runtime."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Extra tags merged onto every taggable resource."
  default     = {}
}
