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
output "full_access_policy_arn" {
  description = "ARN of the full access policy"
  value       = module.ecs_node_role.full_access_policy_arn
}
output "ssh_commands" {
  description = "SSH commands to connect to the instances"
  value = [
    for ip in data.aws_instances.ecs_instances.public_ips :
    "ssh -i ${local_file.private_key.filename} ec2-user@${ip}"
  ]
}

output "key_file_path" {
  description = "Path to the private key file"
  value       = local_file.private_key.filename
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "rendered_user_data" {
  value     = module.ecs_launch_template.rendered_user_data
  sensitive = true
}
output "cleanup_status" {
  description = "Status of cleanup actions during destroy"
  value       = module.cleanup.cleanup_status # Omit the 'condition' argument
}