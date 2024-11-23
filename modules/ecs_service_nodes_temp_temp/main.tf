# modules/ecs_service_nodes/main.tf

resource "aws_ecs_service" "nodejs" {
  name                              = "nodejs-service"  
  cluster                           = var.cluster_id
  task_definition                   = var.task_definition_arn
  desired_count                     = var.desired_count
  health_check_grace_period_seconds = 120
  force_new_deployment              = true

 # Capacity provider strategy
  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_name != "" ? [1] : []
    content {
      capacity_provider = var.capacity_provider_name
      weight           = 100
      base            = 1
    }
  }

 

  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
  }
  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

   dynamic "load_balancer" {
    for_each = range(var.desired_count)
    content {
      target_group_arn = var.nodejs_target_group_arn
      container_name   = var.container_name # This is the correct way to specify container name
      container_port   = var.nodejs_port
    }
  }

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.nodejs.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}
 

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_controller {
    type = "ECS"
  }

  placement_constraints {
    type = "distinctInstance"
  }
 # Network configuration to use private subnets
  network_configuration {
    subnets         = var.private_subnet_ids  # List of private subnet IDs
    security_groups = [var.security_group_id]  # Security group for the ECS tasks
    assign_public_ip = false  # Ensure tasks do not get a public IP
  }
  
  lifecycle {
    create_before_destroy = true
    ignore_changes      = [desired_count]
  }
}

# Security group rule for ECS tasks
resource "aws_security_group_rule" "allow_alb_to_nodejs" {
  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = var.alb_security_group_id
  security_group_id        = var.security_group_id
  description             = "Allow ALB to Node.js ECS Service ${var.service_number}"
}