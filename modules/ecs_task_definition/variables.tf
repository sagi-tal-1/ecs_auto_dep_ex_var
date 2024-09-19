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



variable "example_env_value" {
  description = "Example environment variable value"
  type        = string
}

variable "log_region" {
  description = "AWS region for CloudWatch logs"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the task role"
  type        = string
}


variable "internal_app_port" {
  description = "The port for the internal application (e.g., nodejs)"
  type        = number
  default     = 3000
}

variable "nginx_port" {
  description = "Port number for Nginx container"
  type        = number
}

variable "node_port" {
  description = "Port number for Node.js container"
  type        = number
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group"
  type        = string
}
variable "cloudwatch_log_group_name" {
  description = "ARN of the CloudWatch Log Group"
  type        = string
}