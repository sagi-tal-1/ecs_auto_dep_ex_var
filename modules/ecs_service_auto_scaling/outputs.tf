output "appautoscaling_target_resource_id" {
  description = "The resource ID of the AppAutoscaling target"
  value       = aws_appautoscaling_target.ecs_target.resource_id
}

output "appautoscaling_target_min_capacity" {
  description = "The min capacity of the AppAutoscaling target"
  value       = aws_appautoscaling_target.ecs_target.min_capacity
}

output "appautoscaling_target_max_capacity" {
  description = "The max capacity of the AppAutoscaling target"
  value       = aws_appautoscaling_target.ecs_target.max_capacity
}

output "cpu_policy_name" {
  description = "Name of the CPU target tracking scaling policy"
  value       = aws_appautoscaling_policy.ecs_target_cpu.name
}

output "memory_policy_name" {
  description = "Name of the Memory target tracking scaling policy"
  value       = aws_appautoscaling_policy.ecs_target_memory.name
}
output "asg_arn" {
     value       = var.asg_arn
     description = "The ARN of the Auto Scaling Group"
   }