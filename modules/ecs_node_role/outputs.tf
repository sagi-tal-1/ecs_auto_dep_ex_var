
output "ecs_node_role_arn" {
  description = "ARN of the ECS node IAM role"
  value       = aws_iam_role.ecs_node_role.arn
}

output "ecs_exec_role_arn" {
  description = "ARN of the ECS task execution IAM role"
  value       = aws_iam_role.ecs_exec_role.arn
}

output "ecs_instance_profile_arn" {
  description = "ARN of the ECS instance profile"
  value       = aws_iam_instance_profile.ecs_node.arn
}

output "full_access_policy_arn" {
  description = "ARN of the full access policy"
  value       = aws_iam_policy.full_access.arn
}