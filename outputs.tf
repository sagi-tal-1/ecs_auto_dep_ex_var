output "selected_ecs_optimized_ami_id" {
  description = "The ID of the ECS-optimized AMI that was selected"
  value       = data.aws_ami.ecs_optimized.id
}