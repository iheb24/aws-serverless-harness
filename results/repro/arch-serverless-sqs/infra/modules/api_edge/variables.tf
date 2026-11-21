variable "name" {
  type        = string
  description = "API name; prefixes its log group and resources."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,60}$", var.name))
    error_message = "name must be kebab-case, 2-61 characters."
  }
}

variable "invoke_arn" {
  type        = string
  description = "Invoke ARN of the Lambda function backing the API."
}

variable "function_name" {
  type        = string
  description = "Function name for the lambda permission statement."
}

variable "auth_mode" {
  type        = string
  description = "Authorizer mode: none or jwt (issuer + audience required)."
  default     = "none"

  validation {
    condition     = contains(["none", "jwt"], var.auth_mode)
    error_message = "auth_mode must be none or jwt."
  }

  validation {
    condition     = var.auth_mode != "jwt" || (var.jwt_issuer != null && length(var.jwt_audience) > 0)
    error_message = "jwt auth requires jwt_issuer and jwt_audience."
  }
}

variable "jwt_issuer" {
  type        = string
  description = "OIDC issuer URL for JWT auth."
  default     = null
}

variable "jwt_audience" {
  type        = list(string)
  description = "Allowed JWT audiences."
  default     = []
}

variable "cors_allowed_origins" {
  type        = list(string)
  description = "CORS origins; empty disables CORS configuration."
  default     = []
}

variable "throttle_rate_limit" {
  type        = number
  description = "Steady-state requests per second."
  default     = 100
}

variable "throttle_burst_limit" {
  type        = number
  description = "Burst requests allowed above the rate limit."
  default     = 200
}

variable "stage_name" {
  type        = string
  description = "API stage; $default serves at the root URL."
  default     = "$default"
}

variable "enable_access_log" {
  type        = bool
  description = "Write access logs to a dedicated CloudWatch log group."
  default     = true
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch retention for the access log group."
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Extra tags merged onto every taggable resource."
  default     = {}
}
