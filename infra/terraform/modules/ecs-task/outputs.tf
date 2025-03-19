output "task_definition_arn" {
  description = "The ARN of the task definition"
  value       = aws_ecs_task_definition.main.arn
}

output "container_name" {
  description = "The name of the container"
  value       = "${var.prefix}-container"
}

output "execution_role_arn" {
  description = "The ARN of the execution role"
  value       = aws_iam_role.execution_role.arn
}

output "task_role_arn" {
  description = "The ARN of the task role"
  value       = aws_iam_role.task_role.arn
} 