output "capacity_provider_name" {
  description = "Name of the created ECS capacity provider"
  value       = aws_ecs_capacity_provider.main.name
}

output "capacity_provider_arn" {
  description = "The ARN of the ECS Capacity Provider."
  value       = aws_ecs_capacity_provider.main.arn
}

output "cluster_capacity_providers" {
  value = aws_ecs_cluster_capacity_providers.main.capacity_providers
}


output "asg_arn" {
  description = "The ARN of the Auto Scaling Group"
  value       = var.asg_arn
}