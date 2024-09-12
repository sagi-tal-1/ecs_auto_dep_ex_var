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