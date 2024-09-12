output "capacity_provider_name" {
  description = "Name of the created ECS capacity provider"
  value       = aws_ecs_capacity_provider.main.name
}

output "cluster_capacity_providers" {
  value = aws_ecs_cluster_capacity_providers.main.capacity_providers
}

# Remove or comment out the following output
# output "ecs_cluster" {
#   value = aws_ecs_cluster.main.id
# }
