output "cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "cluster_id" {
  description = "The ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "capacity_provider_name" {
  value = var.capacity_provider_name
}

output "ecs_cluster_id" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}
