output "task_role_arn" {
  value       = aws_iam_role.ecs_task_role.arn
  description = "ARN of the ECS Task Role"
}

output "execution_role_arn" {
  value       = aws_iam_role.ecs_exec_role.arn  # Changed from ecs_execution_role to ecs_exec_role
  description = "ARN of the ECS Task Execution Role"
}