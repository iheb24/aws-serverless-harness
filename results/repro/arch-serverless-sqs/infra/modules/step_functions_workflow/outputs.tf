output "state_machine_arn" {
  description = "State machine ARN."
  value       = aws_sfn_state_machine.this.arn
}

output "state_machine_name" {
  description = "State machine name."
  value       = aws_sfn_state_machine.this.name
}

output "role_arn" {
  description = "Execution role ARN for extra task permissions outside this module."
  value       = aws_iam_role.this.arn
}
