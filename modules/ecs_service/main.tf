#moduls/ecs_service/main.tf

resource "aws_ecs_service" "app" {
  name                               = var.service_name
  cluster                           = var.cluster_id
  task_definition                   = var.task_definition_arn
  desired_count                     = var.desired_count
  health_check_grace_period_seconds = 150
  force_new_deployment              = true
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  
  enable_execute_command           = false

  deployment_circuit_breaker {
    enable   = true
    rollback = true
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
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.nginx_port
  }
  

 

  deployment_controller {
    type = "ECS"
  }
  
  wait_for_steady_state = true

  # Consider making this optional based on your needs
  dynamic "placement_constraints" {
    for_each = var.enable_placement_constraints ? [1] : []
    content {
      type = "distinctInstance"
    }
  }

  # Timeouts
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  # Lifecycle configuration
  lifecycle {
    create_before_destroy = true
    prevent_destroy      = false
    ignore_changes      = [desired_count]
  }

}

# tags = merge(
#     var.tags,
#     {
#       Name        = var.service_name
#       Environment = var.environment
#     }
#   )




# Security group rule for ECS tasks
resource "aws_security_group_rule" "allow_alb_to_ecs" {
  type                     = "ingress"
  from_port                = var.nginx_port
  to_port                  = var.nginx_port
  protocol                 = "tcp"
  source_security_group_id = var.source_security_group_id
  security_group_id        = var.security_group_id
  description             = "Allow ALB to ECS tasks"
}



