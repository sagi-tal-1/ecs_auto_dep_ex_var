# Output the instance profile name for use in launch template
output "ecs_instance_profile_name" {
  value = aws_iam_instance_profile.ecs_instance_profile.name
}

# Output the instance profile arn
output "ecs_instance_profile_arn" {
  value = aws_iam_instance_profile.ecs_instance_profile.arn
}

# Output the task role arn
output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}

# Output the task execution role arn
output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_exec_role.arn
}
