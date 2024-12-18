# modules/autoscaling_group/outputs.tf
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


output "asg_name" {
  value = aws_autoscaling_group.ecs.name
}

# # Output the instance IDs
# output "ec2_instance_ids" {
#   value = data.aws_instances.ecs.ids
# }

output "instance_ids" {
  description = "List of EC2 instance IDs in the Auto Scaling Group"
  value       = data.aws_instances.ecs.ids
}
