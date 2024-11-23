# modules/ecs_service_nodes/variables.tf
variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "cluster_id" {
  description = "ID of the ECS cluster"
  type        = string
}

variable "task_definition_arn" {
  description = "ARN of the task definition"
  type        = string
}

variable "desired_count" {
  description = "Desired number of tasks to run"
  type        = number
  default     = 1
}

variable "capacity_provider_name" {
  description = "Name of the capacity provider"
  type        = string
  default     = ""
}

variable "nodejs_target_group_arn" {
  description = "ARN of the target group for Node.js service"
  type        = string
}

variable "container_name" {
  description = "Name of the Node.js container"
  type        = string
}

variable "nodejs_port" {
  description = "Port number for the Node.js application"
  type        = number
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for the ECS tasks"
  type        = string
}
