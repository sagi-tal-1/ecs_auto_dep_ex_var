# modules/ecs_service_nodes/variables.tf

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "cluster_id" {
  description = "ID of the ECS cluster"
  type        = string
}

variable "nodejs_task_definition_arn" {
  description = "ARN of the Node.js task definition"
  type        = string
}

variable "desired_count" {
  description = "Desired number of Node.js tasks"
  type        = number
  default     = 1
}

variable "capacity_provider_name" {
  description = "Name of the capacity provider"
  type        = string
  default     = ""
}

variable "alb_listener_arn" {
  description = "ARN of the ALB listener"
  type        = string
}

variable "nodejs_target_group_arn" {
  description = "ARN of the target group for Node.js service"
  type        = string
}

variable "nodejs_container_name" {
  description = "Name of the Node.js container"
  type        = string
}

variable "nodejs_port" {
  description = "Port number for the Node.js application"
  type        = number
  default     = 3000
}

variable "security_group_id" {
  description = "ID of the security group"
  type        = string
}

variable "nodejs_name_prefix" {
  description = "Prefix for the service name"
  type        = string
}


variable "alb_dns_name" {
  description = "DNS name of the ALB"
  type        = string
}