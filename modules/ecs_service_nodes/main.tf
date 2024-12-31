# modules/ecs_service_nodes/main.tf
resource "aws_ecs_service" "nodejs" {
  name                              = var.service_name
  cluster                           = var.cluster_id
  task_definition                   = var.task_definition_arn
  desired_count                     = var.desired_count
  launch_type                       = "EC2"
  health_check_grace_period_seconds = 120
  force_new_deployment              = true
  
  enable_execute_command            = true
  enable_ecs_managed_tags          = true
  propagate_tags                   = "SERVICE"
  
  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone == us-east-1a"
  }

  service_registries {
    registry_arn     = var.service_discovery_service_arn  
    container_name   = var.container_name
    container_port   = var.nodejs_port
  }
  
  load_balancer {  
    target_group_arn = var.nodejs_target_group_arn
    container_name   = var.container_name
    container_port   = 3000
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_controller {
    type = "ECS"
  }
 
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  lifecycle {
    create_before_destroy = true
    prevent_destroy      = false
    ignore_changes      = [desired_count, task_definition]
  }
}

resource "aws_security_group_rule" "allow_alb_to_nodejs" {
  type                     = "ingress"
  from_port                = var.nodejs_port
  to_port                  = var.nodejs_port
  protocol                 = "tcp"
  source_security_group_id = var.source_security_group_id
  security_group_id        = var.security_group_id
  description             = "Allow ALB to Node.js ECS tasks"
}




































# resource "aws_ecs_service" "nodejs" {
#   name                              = var.service_name
#   cluster                           = var.cluster_id
#   task_definition                   = var.task_definition_arn
#   desired_count                     = var.desired_count
#   launch_type                       = "EC2"
#   health_check_grace_period_seconds = 120
#   force_new_deployment              = true
  

  
#   ordered_placement_strategy {
#     type  = "binpack"
#     field = "cpu"
#   }
# # Add specific placement constraint for us-east-1a
#   placement_constraints {
#     type       = "memberOf"
#     expression = "attribute:ecs.availability-zone == us-east-1a"
#   }

#   # # Add distinctInstance constraint
#   # placement_constraints {
#   #   type = "distinctInstance"
#   # }

#   #  capacity_provider_strategy {
#   #   capacity_provider = var.capacity_provider_name  
#   #   weight           = 100
#   #   base             = 1
#   # }
#   service_registries {
#     registry_arn = var.service_discovery_service_arn  
#     container_name = var.container_name
#     container_port = var.nodejs_port
#   }
  
#   # Load balancer configuration
#   load_balancer {  
#     target_group_arn = var.nodejs_target_group_arn
#     container_name   = var.container_name
#     container_port   = 3000
#   }
#   # Deployment settings
#   deployment_circuit_breaker {
#     enable   = true
#     rollback = true
#   }
#   deployment_controller {
#     type = "ECS"
#   }
 
#   # Timeouts
#   timeouts {
#     create = "30m"
#     update = "30m"
#     delete = "30m"
#   }

#   lifecycle {
#     create_before_destroy = true
#     prevent_destroy      = false
#     ignore_changes      = [desired_count, task_definition]
#   }
# }

# # Security group rule for ECS tasks
# resource "aws_security_group_rule" "allow_alb_to_nodejs" {
#   type                     = "ingress"
#   from_port                = var.nodejs_port
#   to_port                  = var.nodejs_port
#   protocol                 = "tcp"
#   source_security_group_id = var.source_security_group_id # ALB security group
#   security_group_id        = var.security_group_id  # ECS tasks security group
#   description             = "Allow ALB to Node.js ECS tasks"

 
# }




































  # # Capacity provider strategy
  # dynamic "capacity_provider_strategy" {
  #   for_each = var.capacity_provider_name != "" ? [1] : []
  #   content {
  #     capacity_provider = var.capacity_provider_name
  #     weight           = 100
  #     base            = 1
  #   }
  # }