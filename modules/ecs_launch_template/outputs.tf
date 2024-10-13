output "launch_template_id" {
  value = aws_launch_template.ecs_ec2.id
}


output "ec2_log_stream_name_pattern" {
  description = "The pattern used for EC2 instance log stream names"
  value       = "{instance_id}/ecs-agent"
}


