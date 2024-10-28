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


  lifecycle {
    create_before_destroy = true
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOF
      aws ecs put-cluster-capacity-providers \
        --cluster ${var.cluster_name} \
        --capacity-providers [] \
        --default-capacity-provider-strategy [] || true
    EOF
  }


}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = var.cluster_name
  capacity_providers = [aws_ecs_capacity_provider.main.name]  # Fixed reference to the created capacity provider


  default_capacity_provider_strategy {
    base              = var.base_capacity
    weight            = var.weight
    capacity_provider = aws_ecs_capacity_provider.main.name  # Fixed reference here as well
  }
}