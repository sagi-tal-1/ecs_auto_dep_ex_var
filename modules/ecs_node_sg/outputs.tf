output "security_group_id" {
  description = "ID of the ECS node security group."
  value       = aws_security_group.ecs_node_sg.id
}

output "security_group_arn" {
  description = "ARN of the ECS node security group."
  value       = aws_security_group.ecs_node_sg.arn
}
