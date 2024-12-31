# modules/service_discovery/main.tf

# First create the private DNS namespace
resource "aws_service_discovery_private_dns_namespace" "this" {
  name        = "${var.environment}-services"
  description = "Private DNS namespace for ${var.environment} services"
  vpc         = var.vpc_id
}

# Then create the service discovery service
resource "aws_service_discovery_service" "nodejs" {
  name = var.service_name

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.this.id

    dns_records {
      ttl  = 10
      type = "SRV"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
