output "selected_ecs_optimized_ami_id" {
  description = "The ID of the ECS-optimized AMI that was selected"
  value       = data.aws_ami.ecs_optimized.id
}

output "instance_ips" {
  description = "Public IPs of the EC2 instances in the ECS cluster"
  value       = data.aws_instances.ecs_instances.public_ips
}

output "key_name" {
  description = "The name of the generated key pair for SSH access"
  value       = aws_key_pair.generated_key.key_name
}