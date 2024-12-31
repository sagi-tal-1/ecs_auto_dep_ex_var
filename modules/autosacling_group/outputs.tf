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
  description = "Name of the ECS Auto Scaling Group in AZ-A"
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

# General outputs for both ASGs
output "all_asg_names" {
  description = "Names of all Auto Scaling Groups"
  value       = [aws_autoscaling_group.ecs.name, aws_autoscaling_group.lb.name]
}

output "all_instance_ids" {
  description = "Instance IDs of all instances in the Auto Scaling Groups"
  value       = concat(data.aws_instances.ecs.ids, data.aws_instances.lb.ids)
}