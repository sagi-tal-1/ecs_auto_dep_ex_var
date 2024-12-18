# modules/ecs_service_nodes/variables.tf

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



variable "nodejs_port" {
  description = "Port number for the Node.js application"
  type        = number
}

# variable "private_subnets" {
#   description = "List of private subnet IDs"
#   type        = list(string)
# }

variable "security_group_id" {
  description = "Security group ID for the ECS tasks from ecs taskroll "
  type        = string
}

variable "service_number" {
  description = "Service number identifier"
  type        = string
  default     = "001"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "Dev"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "source_security_group_id" {
  description = "Security group ID for the ECS tasks from ALB "
  type        = string
}



# variable "private_subnet_ids" {
#   description = "List of private subnet IDs"
#   type        = list(string)
# }

variable "container_name" {
  description = "Name of the container"
  type        = string
}
