output "namespace_id" {
  value = aws_service_discovery_private_dns_namespace.this.id
}

output "service_discovery_service_arn" {
  value = aws_service_discovery_service.nodejs.arn
}

output "service_discovery_service_name" {
  value = aws_service_discovery_service.nodejs.name
}

output "service_arn" {
  value = aws_service_discovery_service.nodejs.arn
}