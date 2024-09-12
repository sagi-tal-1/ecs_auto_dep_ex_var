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

output "node_port" {
  value = var.node_port
}