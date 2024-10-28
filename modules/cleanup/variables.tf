# modules/cleanup/variables.tf
variable "aws_region" {
  description = "AWS region where resources are deployed"
  type        = string
}

variable "task_definition_arn" {
  description = "ARN of the ECS task definition to clean up"
  type        = string
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster"
  type        = string
}

variable "cleanup_enabled" {
  description = "Whether cleanup should be performed"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "ID of the VPC where resources are deployed"
  type        = string
}

# modules/cleanup/variables.tf
variable "cluster_name" {
  type        = string
  description = "Name of the ECS cluster"
}

variable "service_name" {
  type        = string
  description = "Name of the ECS service"
}

variable "asg_name" {
  type        = string
  description = "Name of the Auto Scaling Group"
}
