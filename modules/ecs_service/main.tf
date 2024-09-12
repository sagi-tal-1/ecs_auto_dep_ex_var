resource "aws_ecs_service" "app" {
  name            = var.service_name
  cluster         = var.cluster_id
  task_definition = var.task_definition_arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider_name
    weight            = 100
    base              = 1
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "${var.container_name}-nginx"
    container_port   = var.nginx_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_controller {
    type = "ECS"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  network_configuration {
    security_groups = [var.security_group_id]
    subnets         = var.subnet_ids
  }
}