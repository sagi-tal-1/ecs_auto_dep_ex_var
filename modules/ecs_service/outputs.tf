output "service_id" {
  value = aws_ecs_service.app.id
}

output "service_name" {
  value = aws_ecs_service.app.name
}

output "security_group_id" {
  value = var.security_group_id
}

