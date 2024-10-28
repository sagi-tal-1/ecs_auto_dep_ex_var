resource "aws_ecs_service" "app" {
  name            = var.service_name
  cluster         = var.cluster_id
  task_definition = var.task_definition_arn
  desired_count   = var.desired_count
  depends_on      = [var.alb_listener_arn]

  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_name != "" ? [1] : []
    content {
      capacity_provider = var.capacity_provider_name
      weight            = 100
      base              = 1
    }
  }

  # ordered_placement_strategy {
  #   type  = "spread"
  #   field = "attribute:ecs.availability-zone"
  # }

  # ordered_placement_strategy {
  #   type  = "binpack"
  #   field = "memory"
  # }

  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
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

 placement_constraints {
    type = "distinctInstance"
  }
  health_check_grace_period_seconds = 60
  lifecycle {
    create_before_destroy = true
    
    # Add this to prevent destroy if tasks are running
    prevent_destroy = false
  }

  provisioner "local-exec" {
    when    = destroy
    command = "aws ecs update-service --cluster ${var.cluster_name} --service ${self.name} --desired-count 0 || true"
  }
 
 
  # no network conf as task defenition uses bridg network
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
#       weight            = 100
#       base              = 1
#     }
#   }

#   ordered_placement_strategy {
#     type  = "spread"
#     field = "instanceId"
#   }
# network_configuration {
#     security_groups = [var.security_group_id]
#     subnets         = var.subnet_ids
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

#   lifecycle {
#     ignore_changes = [desired_count]
#   }



#   # Add this to ensure proper task placement
#   placement_constraints {
#     type = "distinctInstance"
#   }

# }
