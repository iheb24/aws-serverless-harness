variable "name" {
  type        = string
  description = "Function name; also prefixes its role, log group, and DLQ."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,60}$", var.name))
    error_message = "name must be kebab-case, 2-61 characters."
  }
}

variable "package_type" {
  type        = string
  description = "Deployment artifact kind: Zip (handler/runtime) or Image (image_uri)."
  default     = "Zip"

  validation {
    condition     = contains(["Zip", "Image"], var.package_type)
    error_message = "package_type must be Zip or Image."
  }
}

variable "filename" {
  type        = string
  description = "Path to the deployment zip; required when package_type is Zip."
  default     = null

  validation {
    condition     = var.package_type != "Zip" || (var.filename != null && var.handler != null)
    error_message = "filename and handler are required when package_type is Zip."
  }
}

variable "source_code_hash" {
  type        = string
  description = "Base64 SHA256 of the zip; drives redeploy detection for Zip packages."
  default     = null
}

variable "image_uri" {
  type        = string
  description = "ECR image URI; required when package_type is Image."
  default     = null

  validation {
    condition     = var.package_type != "Image" || var.image_uri != null
    error_message = "image_uri is required when package_type is Image."
  }
}

variable "handler" {
  type        = string
  description = "Entrypoint such as order_worker.entrypoint.handler; Zip only."
  default     = null
}

variable "runtime" {
  type        = string
  description = "Lambda runtime identifier; Zip only."
  default     = "python3.13"
}

variable "memory_size" {
  type        = number
  description = "Function memory in MB."
  default     = 256

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "memory_size must be between 128 and 10240 MB."
  }
}

variable "timeout" {
  type        = number
  description = "Function timeout in seconds."
  default     = 30

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "timeout must be between 1 and 900 seconds."
  }
}

variable "environment_variables" {
  type        = map(string)
  description = "Plain environment variables; SSM paths and secret ARNs passed as strings."
  default     = {}
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention."
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a valid CloudWatch retention value."
  }
}

variable "policy_statements" {
  type = list(object({
    actions   = list(string)
    resources = list(string)
  }))
  description = "Least-privilege IAM statements merged into the execution role."
  default     = []
}

variable "triggers" {
  type = object({
    sqs = optional(object({
      queue_arn                       = string
      batch_size                      = optional(number, 10)
      maximum_batching_window_seconds = optional(number, 0)
    }))
    sns = optional(object({
      topic_arn = string
    }))
    eventbridge = optional(object({
      rule_arn = string
    }))
    schedule = optional(object({
      expression = string
    }))
    dynamodb_stream = optional(object({
      stream_arn        = string
      batch_size        = optional(number, 100)
      starting_position = optional(string, "LATEST")
    }))
    s3 = optional(object({
      bucket_name   = string
      bucket_arn    = string
      events        = optional(list(string), ["s3:ObjectCreated:*"])
      filter_prefix = optional(string)
      filter_suffix = optional(string)
    }))
  })
  description = "Event sources wired to the function; only present keys create resources."
  default     = {}
}

variable "enable_dlq" {
  type        = bool
  description = "Create a function-level SQS dead-letter queue for async invocations."
  default     = true
}

variable "dlq_message_retention_seconds" {
  type        = number
  description = "Retention for dead-lettered messages."
  default     = 1209600
}

variable "kms_key_arn" {
  type        = string
  description = "Customer-managed CMK for logs, env, and DLQ; aws-managed keys when null."
  default     = null
}

variable "vpc_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs; empty keeps the function outside any VPC."
  default     = []
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "Security groups attached when vpc_subnet_ids is set."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Extra tags merged onto every taggable resource."
  default     = {}
}
