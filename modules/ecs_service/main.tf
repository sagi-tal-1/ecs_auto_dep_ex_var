#moduls/ecs_service/main.tf
resource "aws_ecs_service" "app" {
  name                               = var.service_name
  cluster                           = var.cluster_id
  task_definition                   = var.task_definition_arn
  desired_count                     = var.desired_count
  health_check_grace_period_seconds = 120
  force_new_deployment              = true

  depends_on = [var.alb_listener_arn]

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
    container_name   = "${var.container_name}-nginx"
    container_port   = var.nginx_port
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
resource "aws_security_group_rule" "allow_alb_to_ecs" {
  type                     = "ingress"
  from_port                = var.nginx_port
  to_port                  = var.nginx_port
  protocol                 = "tcp"
  source_security_group_id = var.security_group_id
  security_group_id        = var.security_group_id
  description             = "Allow ALB to ECS tasks"
}






# resource "aws_ecs_service" "app" {
#   name            = var.service_name
#   cluster         = var.cluster_id
#   task_definition = var.task_definition_arn
#   desired_count   = var.desired_count
#   depends_on      = [var.alb_listener_arn]



#   dynamic "capacity_provider_strategy" {
#     for_each = var.capacity_provider_name != "" ? [1] : []
#     content {
#       capacity_provider = var.capacity_provider_name
#       weight           = 100
#       base             = 1
#     }
#   }

#   ordered_placement_strategy {
#     type  = "spread"
#     field = "instanceId"
#   }
   
#   load_balancer {
#     target_group_arn = var.target_group_arn
#     container_name   = "${var.container_name}-nginx"
#     container_port   = var.nginx_port
#   }
 
#   deployment_circuit_breaker {
#     enable   = true
#     rollback = true
#   }

#   deployment_controller {
#     type = "ECS"
#   }

#   placement_constraints {
#     type = "distinctInstance"
#   }

#  timeouts {
#     create = "30m"
#     update = "30m"
#     delete = "30m"
#   }

#   lifecycle {
#     create_before_destroy = true
#     prevent_destroy = false
#   }

#  health_check_grace_period_seconds = 60

# }