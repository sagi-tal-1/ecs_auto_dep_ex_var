variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "asg_names" {
  description = "Name of the Auto Scaling Group"
    type        = list(string)
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


variable "all_instance_ids" {
  description = "Instance IDs of all instances in the Auto Scaling Groups"
  type        = list(string)
}
