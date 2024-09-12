output "vpc_id" {
  description = "The ID of the VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets."
  value       = module.vpc.subnet_ids
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway."
  value       = module.internet_gateway.internet_gateway_id
}




output "ecs_cluster_id" {
  description = "The ID of the ECS cluster."
  value       = module.ecs_cluster.cluster_id
}

output "ecs_service_name" {
  description = "The name of the ECS service."
  value       = module.ecs_service.ecs_service_name
}

output "ecs_task_role_arn" {
  value = module.ecs_task_role.ecs_task_role_arn
}

output "ecs_exec_role_arn" {
  value = module.ecs_task_role.ecs_exec_role_arn
}

output "ecs_launch_template_id" {
  value = module.ecs_launch_template.launch_template_id
}

output "ecs_asg_id" {
  value = module.ecs_asg.asg_id
}



output "cluster_capacity_providers_id" {
  value = module.ecs_capacity_provider.cluster_capacity_providers
}
output "cloudwatch_log_group_name" {
  value = module.cloudwatch_logs.log_group_name
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer."
  value       = module.alb.alb_dns_name
}

output "alb_target_group_arn" {
  description = "The ARN of the ALB Target Group."
  value       = module.alb.target_group_arn
}

output "ecs_service" {
  description = "The ARN of the ALB Target Group."
  value       = module.alb.target_group_arn
}


output "task_definition_arn" {
  description = "The ARN of the ECS task definition"
  value       = module.ecs_task_definition.task_definition_arn
}

output "nginx_log_stream_arn" {
  value = module.cloudwatch_logs.nginx_log_stream_arn
}

output "nodejs_log_stream_arn" {
  value = module.cloudwatch_logs.nodejs_log_stream_arn
}

