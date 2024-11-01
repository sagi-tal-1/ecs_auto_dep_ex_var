
#moduls/ecs_service/virabels.tf
variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "cluster_id" {
  description = "ID of the ECS cluster"
  type        = string
}

variable "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  type        = string
}

variable "task_definition_arn" {
  description = "ARN of the task definition"
  type        = string
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "target_group_arn" {
  description = "ARN of the target group"
  type        = string
}

variable "container_name" {
  description = "Name of the container"
  type        = string
}

variable "capacity_provider_name" {
  description = "Name of the capacity provider"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the ECS tasks will run"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for the service name"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  type        = string
}

variable "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  type        = string
}

variable "security_group_id" {
  description = "ID of the security group for ECS tasks"
  type        = string
}

variable "nginx_port" {
  description = "Port number for Nginx container"
  type        = number
}

variable "retention_in_days" {
  description = "Retention period for the CloudWatch Log Group (in days)"
  type        = number
  default     = 1
}

variable "network_mode" {
  description = "Network mode of the task definition (awsvpc, bridge, host, or none)"
  type        = string
  default     = "bridge"
}

# Add the missing alb_listener_arn variable
variable "alb_listener_arn" {
  description = "ARN of the ALB listener"
  type        = string
}