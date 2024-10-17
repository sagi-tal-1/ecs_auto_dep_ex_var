resource "aws_ecs_cluster" "main" {
  name = var.cluster_name



}

# resource "aws_ecs_capacity_provider" "main" {
#   name = "${var.cluster_name}-capacity-provider"

#   auto_scaling_group_provider {
#     auto_scaling_group_arn = var.asg_arn
    
#     managed_scaling {
#       maximum_scaling_step_size = 1000
#       minimum_scaling_step_size = 1
#       status                    = "ENABLED"
#       target_capacity           = 100
#     }
#   }
# }

# resource "aws_ecs_cluster_capacity_providers" "main" {
#   cluster_name = aws_ecs_cluster.main.name
#   capacity_providers = [aws_ecs_capacity_provider.main.name]

#   default_capacity_provider_strategy {
#     base              = 1
#     weight            = 100
#     capacity_provider = aws_ecs_capacity_provider.main.name
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

