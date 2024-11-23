# modules/ecs_service_nodes/main.tf
resource "aws_ecs_service" "nodejs" {
  name                              = var.service_name
  cluster                           = var.cluster_id
  task_definition                   = var.task_definition_arn
  desired_count                     = var.desired_count
  health_check_grace_period_seconds = 120
  force_new_deployment              = true
  
  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }
  # Capacity provider strategy
  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_name != "" ? [1] : []
    content {
      capacity_provider = var.capacity_provider_name
      weight           = 100
      base            = 1
    }
  }
  # Placement strategies
  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }
  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
  }
  # Load balancer configuration
  load_balancer {
    target_group_arn = var.nodejs_target_group_arn
    container_name   = var.container_name
    container_port   = 3000
  }
network_configuration {
    subnets          = var.private_subnets
    security_groups  = [var.security_group_id]
    assign_public_ip = false
  }
  # Deployment settings
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  deployment_controller {
    type = "ECS"
  }
  # Placement constraints
  placement_constraints {
    type = "distinctInstance"
  }
  # Timeouts
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
  lifecycle {
    create_before_destroy = true
    prevent_destroy      = false
    ignore_changes      = [desired_count]
  }
  
}
# Security group rule for ECS tasks
resource "aws_security_group_rule" "allow_alb_to_nodejs" {
  type                     = "ingress"
  from_port                = var.nodejs_port
  to_port                  = var.nodejs_port
  protocol                 = "tcp"
  source_security_group_id = var.security_group_id
  security_group_id        = var.security_group_id
  description             = "Allow ALB to Node.js ECS tasks"

 
}
