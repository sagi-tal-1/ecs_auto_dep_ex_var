# modules/alb/outputs.tf
output "target_group_arn" {
  description = "The ARN of the created target group"
  value       = aws_lb_target_group.ec2.arn
}
output "alb_arn" {
  description = "The ARN of the load balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}
output "alb_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.main.name
}
output "security_group_id" {
  value = aws_security_group.http.id
}

 #the listener ARN
output "alb_listener_arn" {
  description = "ARN of the ALB listener"
  value       = aws_lb_listener.alb_ec2.arn
}

# Output for the Target Group ARN
output "nginx_ecs_target_group_arn" {
  description = "The ARN of the target group for ECS nginx service"
  value       = aws_lb_target_group.nginx_ecs.arn
}


# Output for ECS tasks security group ID
output "nginx_ecs_tasks_security_group_id" {
  description = "The ID of the security group for ECS tasks"
  value       = aws_security_group.nginx_ecs_tasks.id
}


# Output for Listener Rule ARN
output "nginx_ecs_listener_rule_arn" {
  description = "The ARN of the listener rule for ECS nginx service"
  value       = aws_lb_listener_rule.nginx_ecs.arn
}

output "nodejs_ecs_target_group_arn" {
  description = "ARN of the target group for nodejs ECS service"
  value       = aws_lb_target_group.nodejs_ecs.arn
}

output "nodejs_ecs_security_group_id" {
  description = "Security group ID for nodejs ECS tasks"
  value       = aws_security_group.nodejs_ecs_tasks.id
}








# output "nginx_security_group_id" {
#   description = "The ID of the NGINX ECS security group"
#   value       = aws_security_group.nginx_ecs.id
# }

# output "nodejs_security_group_id" {
#   description = "The ID of the NodeJS ECS security group"
#   value       = aws_security_group.nodejs_ecs.id
# }

# output "nginx_target_group_arn" {
#   description = "The ARN of the NGINX target group"
#   value       = aws_lb_target_group.app.arn
# }

# output "nodejs_target_group_arn" {
#   description = "The ARN of the NodeJS target group"
#   value       = aws_lb_target_group.nodejs.arn
# }

output "ec2_security_group_id" {
  value       = aws_security_group.ec2.id
  description = "The ID of the EC2 security group to be used by other modules."
}
output "ec2_target_group_arn" {
  value       = aws_lb_target_group.ec2.arn
  description = "The ARN of the EC2 target group."
}

output "ec2_target_group_name" {
  value       = aws_lb_target_group.ec2.name
  description = "The name of the EC2 target group."
}