# modules/ecs_task_defenition_node/outputs.tf

output "nodejs_port" {
  value = var.nodejs_port
}
output "task_definition_arn" {
  value       = aws_ecs_task_definition.app.arn
}

# Output the service discovery service ARN and name
# output "service_discovery_service_arn" {
#   value = aws_service_discovery_service.nodejs.arn
# }

# output "service_discovery_service_name" {
#   value = aws_service_discovery_service.nodejs.name
# }

output "task_definition_family" {
  description = "Family of the task definition"
  value       = aws_ecs_task_definition.app[*].family
}

