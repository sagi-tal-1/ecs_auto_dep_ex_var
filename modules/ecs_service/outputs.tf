# modules/ecs_service/outputs.tf
output "service_id" {
  value = aws_ecs_service.app.id
}

output "service_name" {
  value = aws_ecs_service.app.name
}

output "security_group_id" {
  value = var.security_group_id
}

output "service_status" {
  description = "Current status of ECS service"
  value = {
    desired_count = aws_ecs_service.app.desired_count
    cluster       = var.cluster_id
    service_arn   = aws_ecs_service.app.id
  }
}

output "service_url" {
  value       = "http://${var.alb_dns_name}:${var.nginx_port}"
  description = "URL of the ECS service accessible via ALB"
}

output "container_name" {
  description = "Container name used in ECS service"
  value       = var.container_name
}