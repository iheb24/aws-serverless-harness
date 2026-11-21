variable "name" {
  type        = string
  description = "Job name; prefixes queue, definition, roles, and log group."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,60}$", var.name))
    error_message = "name must be kebab-case, 2-61 characters."
  }
}

variable "image_uri" {
  type        = string
  description = "Full container image URI for the job definition."
}

variable "compute_type" {
  type        = string
  description = "FARGATE for on-demand capacity, FARGATE_SPOT for cheaper interruptible capacity."
  default     = "FARGATE"

  validation {
    condition     = contains(["FARGATE", "FARGATE_SPOT"], var.compute_type)
    error_message = "compute_type must be FARGATE or FARGATE_SPOT."
  }
}

variable "command" {
  type        = list(string)
  description = "Container command override; empty uses the image default."
  default     = []
}

variable "vcpus" {
  type        = number
  description = "Job vCPU allocation."
  default     = 1
}

variable "memory" {
  type        = number
  description = "Job memory in MB."
  default     = 2048
}

variable "retry_attempts" {
  type        = number
  description = "Job retry attempts on failure."
  default     = 2

  validation {
    condition     = var.retry_attempts >= 1 && var.retry_attempts <= 10
    error_message = "retry_attempts must be between 1 and 10."
  }
}

variable "timeout_seconds" {
  type        = number
  description = "Hard job timeout in seconds."
  default     = 3600

  validation {
    condition     = var.timeout_seconds >= 60 && var.timeout_seconds <= 86400
    error_message = "timeout_seconds must be between 60 and 86400."
  }
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the Fargate compute environment."
  default     = []
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security groups for job networking."
  default     = []
}

variable "create_ecr" {
  type        = bool
  description = "Create the ECR repository with scan-on-push and immutable tags."
  default     = true
}

variable "environment" {
  type        = map(string)
  description = "Plain environment variables injected into the job container."
  default     = {}
}

variable "secrets" {
  type        = map(string)
  description = "Map of env var name to Secrets Manager ARN injected as job secrets."
  default     = {}
}

variable "policy_statements" {
  type = list(object({
    actions   = list(string)
    resources = list(string)
  }))
  description = "Least-privilege IAM statements for the job role."
  default     = []
}

variable "trigger_schedule" {
  type        = string
  description = "Optional EventBridge Scheduler expression that submits the job."
  default     = null
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch retention for job logs."
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Extra tags merged onto every taggable resource."
  default     = {}
}
