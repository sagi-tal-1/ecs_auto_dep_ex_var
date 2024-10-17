variable "capacity_provider_name" {
  type        = string
  description = "Name of the ECS capacity provider"
}

variable "asg_arn" {
  type        = string
  description = "ARN of the Auto Scaling Group"
  
}

variable "cluster_name" {
  type        = string
  description = "Name of the ECS cluster"
}

variable "max_scaling_step_size" {
  type        = number
  description = "The maximum scaling step size for the capacity provider."
}

variable "min_scaling_step_size" {
  type        = number
  description = "The minimum scaling step size for the capacity provider."
}

variable "target_capacity" {
  type        = number
  description = "The target capacity for the capacity provider."
}

variable "base_capacity" {
  type        = number
  description = "The base capacity for the capacity provider."
}

variable "weight" {
  type        = number
  description = "The weight of the capacity provider."
}