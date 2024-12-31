# modules/ecs_service_nodes/variables.tf
variable "family" {
  description = "A unique name for your task definition family"
  type        = string
}
variable "container_name" {
  description = "Name of the container"
  type        = string
}
variable "log_group_name" {
  description = "Name of the CloudWatch log group"
  type        = string
}

variable "log_stream_prefix" {
  description = "Prefix for the log stream"
  type        = string
}

variable "cpu" {
  description = "CPU units for the task"
  type        = number
}

variable "memory" {
  description = "Memory for the task in MiB"
  type        = number
}
variable "docker_image" {
  description = "The Docker image to use for the container"
  type        = string
}
variable "nodejs_port" {
  description = "Port number for Nginx container"
  type        = number
}
variable "execution_role_arn" {
  description = "ARN of the task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the task role"
  type        = string
}
variable "log_region" {
  description = "AWS region for CloudWatch logs"
  type        = string
}
variable "log_group_arn" {
  description = "ARN of the CloudWatch Log Group"
  type        = string
}

# modules/ecs_task_definition_node/variables.tf
variable "desired_count" {
  description = "Number of task definitions to create"
  type        = number
  default     = 2
}
#--------------------

# variable "service_discovery_namespace_id" {
#   description = "The ID of the AWS Cloud Map namespace"
#   type        = string
# }
variable "service_discovery_service_name" {
  description = "Name of the service discovery service"
  type        = string
}

variable "service_discovery_namespace" {
  description = "The name of the AWS Cloud Map namespace"
  type        = string
}

variable "cluster_name" {
  type        = string
  description = "Name of the ECS cluster"
}
variable "service_name" {
  type        = string
  description = "Name of the ECS service"
}

variable "environment" {
  type        = string
  description = "Name of the ECS environment"
}