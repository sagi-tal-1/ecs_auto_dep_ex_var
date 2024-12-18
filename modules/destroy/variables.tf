variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "task_family" {
  description = "Family name of the task definition"
  type        = string
}
variable "service_name_nodes" {
  description = "Name of the ECS service for nodes"
  type        = string
  default     = null
}