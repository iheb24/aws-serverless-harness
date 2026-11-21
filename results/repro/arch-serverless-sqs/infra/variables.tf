variable "project_name" {
  type        = string
  description = "Project slug used as prefix for all resource names."
  default     = "arch-serverless-sqs"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.project_name))
    error_message = "project_name must be kebab-case."
  }
}

variable "aws_region" {
  type        = string
  description = "Primary AWS region for all resources."
  default     = "eu-west-3"
}

variable "environment" {
  type        = string
  description = "Deployment stage; controls naming and sizing switches."
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of dev, staging, prod."
  }
}
