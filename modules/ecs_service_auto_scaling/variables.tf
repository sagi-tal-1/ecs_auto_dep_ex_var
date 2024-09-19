variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "min_capacity" {
  description = "Minimum number of tasks"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of tasks"
  type        = number
  default     = 5
}

variable "target_cpu_value" {
  description = "Target CPU utilization percentage"
  type        = number
  default     = 80
}

variable "target_memory_value" {
  description = "Target Memory utilization percentage"
  type        = number
  default     = 80
}