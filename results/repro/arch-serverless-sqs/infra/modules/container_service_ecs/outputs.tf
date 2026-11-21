output "cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.this.name
}

output "task_definition_arn" {
  description = "Task definition ARN."
  value       = aws_ecs_task_definition.this.arn
}

output "service_name" {
  description = "ECS service name; null in scheduled_task mode."
  value       = local.is_service_mode ? aws_ecs_service.this[0].name : null
}

output "ecr_repository_url" {
  description = "ECR repository URL; null when create_ecr is false."
  value       = var.create_ecr ? aws_ecr_repository.this[0].repository_url : null
}

output "log_group_name" {
  description = "CloudWatch log group receiving task logs."
  value       = aws_cloudwatch_log_group.this.name
}
