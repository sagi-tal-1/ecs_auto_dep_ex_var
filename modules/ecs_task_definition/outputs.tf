#moduls/ecs_task_definition/output.tf

output "task_definition_arn" {
  value = aws_ecs_task_definition.app.arn
}

output "family" {
  value = aws_ecs_task_definition.app.family
}

output "container_name" {
  value = var.container_name
}

output "container_port" {
  value = 80
}

output "nginx_port" {
  value = var.nginx_port
}

# output "node_port" {
#   value = var.node_port
# }

output "node_port" {
     value = var.node_port != null ? var.node_port : null
   }

 

output "task_definition_container_definitions" {
  description = "Container definitions JSON"
  value       = aws_ecs_task_definition.app.container_definitions
}

