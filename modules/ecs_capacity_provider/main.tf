resource "aws_ecs_capacity_provider" "main" {
  name = var.capacity_provider_name

  auto_scaling_group_provider {
    auto_scaling_group_arn         = var.asg_arn
    managed_termination_protection = "DISABLED"


    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = var.target_capacity
      maximum_scaling_step_size = var.max_scaling_step_size
      minimum_scaling_step_size = var.min_scaling_step_size
      
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = var.cluster_name
  capacity_providers = [aws_ecs_capacity_provider.main.name]

  default_capacity_provider_strategy {
    base              = var.base_capacity
    weight            = var.weight
    capacity_provider = aws_ecs_capacity_provider.main.name
  }
}