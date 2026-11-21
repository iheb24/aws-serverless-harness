variable "name" {
  type        = string
  description = "Service name; prefixes cluster, task, roles, and log group."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,60}$", var.name))
    error_message = "name must be kebab-case, 2-61 characters."
  }
}

variable "image_uri" {
  type        = string
  description = "Full container image URI, e.g. <account>.dkr.ecr.<region>.amazonaws.com/<repo>:<tag>."
}

variable "execution_mode" {
  type        = string
  description = "service for a long-running service, sqs_autoscale_worker to scale on queue depth, scheduled_task for cron."
  default     = "sqs_autoscale_worker"

  validation {
    condition     = contains(["service", "sqs_autoscale_worker", "scheduled_task"], var.execution_mode)
    error_message = "execution_mode must be service, sqs_autoscale_worker, or scheduled_task."
  }

  validation {
    condition     = var.execution_mode != "sqs_autoscale_worker" || var.queue_arn != null
    error_message = "sqs_autoscale_worker requires queue_arn."
  }

  validation {
    condition     = var.execution_mode != "scheduled_task" || var.schedule_expression != null
    error_message = "scheduled_task requires schedule_expression."
  }
}

variable "queue_arn" {
  type        = string
  description = "SQS queue ARN driving autoscaling in sqs_autoscale_worker mode."
  default     = null
}

variable "schedule_expression" {
  type        = string
  description = "Scheduler expression (rate/cron) in scheduled_task mode."
  default     = null
}

variable "cpu" {
  type        = number
  description = "Fargate task CPU units."
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.cpu)
    error_message = "cpu must be a valid Fargate tier."
  }
}

variable "memory" {
  type        = number
  description = "Fargate task memory in MB."
  default     = 512
}

variable "desired_count" {
  type        = number
  description = "Tasks kept running in service or worker modes."
  default     = 1
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for task placement."
  default     = []
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security groups attached to tasks."
  default     = []
}

variable "assign_public_ip" {
  type        = bool
  description = "Assign public IPs to tasks; keep false with private subnets."
  default     = false
}

variable "create_ecr" {
  type        = bool
  description = "Create the ECR repository with scan-on-push and immutable tags."
  default     = true
}

variable "environment" {
  type        = map(string)
  description = "Plain environment variables injected into the container."
  default     = {}
}

variable "secrets" {
  type        = map(string)
  description = "Map of env var name to Secrets Manager ARN injected as container secrets."
  default     = {}
}

variable "policy_statements" {
  type = list(object({
    actions   = list(string)
    resources = list(string)
  }))
  description = "Least-privilege IAM statements for the task role."
  default     = []
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch retention for task logs."
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Extra tags merged onto every taggable resource."
  default     = {}
}
