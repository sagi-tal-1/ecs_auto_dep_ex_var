output "asg_id" {
  value = aws_autoscaling_group.ecs.id 
}

output "asg_arn" {
  description = "The ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.ecs.arn
}

output "autoscaling_group_name" {
  description = "The name of the Auto Scaling Group"
  value       = aws_autoscaling_group.ecs.name  # Changed from 'main' to 'ecs'
}

