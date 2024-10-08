output "role_arn" {
  description = "ARN of the ECS node role."
  value       = aws_iam_role.ecs_node_role.arn
}

output "instance_profile_arn" {
  description = "ARN of the ECS node instance profile."
  value       = aws_iam_instance_profile.ecs_node.arn
}

output "ecs_exec_role_arn" {
  description = "ARN of the ECS task execution role."
  value       = aws_iam_role.ecs_exec_role.arn
}

output "ecr_policy_arn" {
  description = "ARN of the ECR policy."
  value       = aws_iam_policy.ecr_policy.arn
}

output "cloudwatch_logs_policy_arn" {
  description = "ARN of the CloudWatch Logs policy."
  value       = aws_iam_policy.cloudwatch_logs_policy.arn
}
output "ec2_full_access_policy_arn" {
  description = "ARN of the EC2 full access policy"
  value       = aws_iam_policy.ec2_full_access.arn
}