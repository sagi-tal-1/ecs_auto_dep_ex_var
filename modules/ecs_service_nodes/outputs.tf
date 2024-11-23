# modules/ecs_service_nodes/outputs.tf

output "service_id" {
  description = "The ID of the ECS service"
  value       = aws_ecs_service.nodejs.id
}

output "service_name" {
  description = "The name of the ECS service"
  value       = aws_ecs_service.nodejs.name
}

output "service_arn" {
  description = "The ARN of the ECS service"
  value       = aws_ecs_service.nodejs.id
}

output "security_group_rule_id" {
  description = "The ID of the security group rule"
  value       = aws_security_group_rule.allow_alb_to_nodejs.id
}
output "container_name" {
  value = var.container_name
}