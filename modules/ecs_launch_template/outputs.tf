#moduls/ecs_launch_template/outputs.tf
output "launch_template_id" {
  value = aws_launch_template.ecs_ec2.id
}


output "ec2_log_stream_name_pattern" {
  description = "The pattern used for EC2 instance log stream names"
  value       = "{instance_id}/ecs-agent"
}


output "rendered_user_data" {
  value = templatefile("${path.module}/user_data.tpl", {
    cluster_name       = var.cluster_name
    log_group_name     = var.log_group_name
    log_stream_name    = var.log_stream_name
    region             = data.aws_region.current.name
    LOG_FILE           = var.log_file
    ERROR_LOG          = var.error_log
   
  })
  sensitive = true
}

output "module_path" {
  value = path.module
}