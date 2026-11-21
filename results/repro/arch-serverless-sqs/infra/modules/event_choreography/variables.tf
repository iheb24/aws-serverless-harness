variable "name" {
  type        = string
  description = "Base name for the queue, topic, or event bus."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,60}$", var.name))
    error_message = "name must be kebab-case, 2-61 characters."
  }
}

variable "pattern" {
  type        = string
  description = "Messaging topology to provision."
  default     = "sqs_queue"

  validation {
    condition     = contains(["sqs_queue", "sns_to_sqs_fanout", "custom_event_bus"], var.pattern)
    error_message = "pattern must be sqs_queue, sns_to_sqs_fanout, or custom_event_bus."
  }
}

variable "fifo_enabled" {
  type        = bool
  description = "Use FIFO semantics (strict ordering, exactly-once) for queue or fanout."
  default     = false
}

variable "fifo_content_based_deduplication" {
  type        = bool
  description = "Let SQS/SNS deduplicate by content hash instead of explicit dedup ids."
  default     = false
}

variable "enable_redrive_dlq" {
  type        = bool
  description = "Attach a dead-letter queue with a redrive policy to the main queue."
  default     = true
}

variable "max_receive_count" {
  type        = number
  description = "Deliveries attempted before a message moves to the DLQ."
  default     = 3

  validation {
    condition     = var.max_receive_count >= 1 && var.max_receive_count <= 1000
    error_message = "max_receive_count must be between 1 and 1000."
  }
}

variable "visibility_timeout_seconds" {
  type        = number
  description = "Queue visibility timeout; set to at least 6x the consumer Lambda timeout."
  default     = 30

  validation {
    condition     = var.visibility_timeout_seconds >= 0 && var.visibility_timeout_seconds <= 43200
    error_message = "visibility_timeout_seconds must be between 0 and 43200."
  }
}

variable "queue_kms_key_arn" {
  type        = string
  description = "Customer-managed CMK for queue/topic encryption; aws-managed SSE when null."
  default     = null
}

variable "archive_days" {
  type        = number
  description = "EventBridge archive retention in days for replay; 0 disables the archive."
  default     = 0

  validation {
    condition     = var.archive_days == 0 || (var.archive_days >= 1 && var.archive_days <= 365)
    error_message = "archive_days must be 0 (disabled) or between 1 and 365."
  }
}

variable "tags" {
  type        = map(string)
  description = "Extra tags merged onto every taggable resource."
  default     = {}
}
