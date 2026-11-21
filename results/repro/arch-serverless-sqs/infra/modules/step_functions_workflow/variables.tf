variable "name" {
  type        = string
  description = "State machine name; prefixes its role and log group."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,60}$", var.name))
    error_message = "name must be kebab-case, 2-61 characters."
  }
}

variable "workflow_type" {
  type        = string
  description = "STANDARD for durable long-running flows; EXPRESS for high-rate short ones."
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "EXPRESS"], var.workflow_type)
    error_message = "workflow_type must be STANDARD or EXPRESS."
  }
}

variable "asl_definition" {
  type        = string
  description = "Amazon States Language definition; reference task ARNs via task_lambda_arns."

  validation {
    condition     = can(jsondecode(var.asl_definition))
    error_message = "asl_definition must be valid JSON."
  }
}

variable "task_lambda_arns" {
  type        = map(string)
  description = "Map of logical task label to Lambda ARN; grants states InvokeFunction on each."
  default     = {}
}

variable "enable_xray" {
  type        = bool
  description = "Enable X-Ray tracing on executions."
  default     = false
}

variable "log_level" {
  type        = string
  description = "Execution log level: OFF, ERROR, or ALL."
  default     = "ERROR"

  validation {
    condition     = contains(["OFF", "ERROR", "ALL"], var.log_level)
    error_message = "log_level must be OFF, ERROR, or ALL."
  }
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch retention for execution logs."
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Extra tags merged onto every taggable resource."
  default     = {}
}
