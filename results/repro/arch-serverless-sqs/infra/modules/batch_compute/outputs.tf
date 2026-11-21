output "job_queue_arn" {
  description = "Batch job queue ARN."
  value       = aws_batch_job_queue.this.arn
}

output "job_queue_name" {
  description = "Batch job queue name."
  value       = aws_batch_job_queue.this.name
}

output "job_definition_arn" {
  description = "Batch job definition ARN."
  value       = aws_batch_job_definition.this.arn
}

output "ecr_repository_url" {
  description = "ECR repository URL; null when create_ecr is false."
  value       = var.create_ecr ? aws_ecr_repository.this[0].repository_url : null
}

output "log_group_name" {
  description = "CloudWatch log group receiving job logs."
  value       = aws_cloudwatch_log_group.this.name
}
