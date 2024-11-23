# modules/alb/outputs.tf
output "target_group_arn" {
  description = "The ARN of the created target group"
  value       = aws_lb_target_group.app.arn
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

#  the listener ARN
output "listener_arn" {
  description = "The ARN of the ALB listener"
  value       = aws_lb_listener.http.arn
}
output "nginx_security_group_id" {
  description = "The ID of the NGINX ECS security group"
  value       = aws_security_group.nginx_ecs.id
}

output "nodejs_security_group_id" {
  description = "The ID of the NodeJS ECS security group"
  value       = aws_security_group.nodejs_ecs.id
}

output "nginx_target_group_arn" {
  description = "The ARN of the NGINX target group"
  value       = aws_lb_target_group.app.arn
}

output "nodejs_target_group_arn" {
  description = "The ARN of the NodeJS target group"
  value       = aws_lb_target_group.nodejs.arn
}
