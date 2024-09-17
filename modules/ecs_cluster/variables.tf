variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "capacity_providers" {
  description = "List of short names of one or more capacity providers to associate with the cluster"
  type        = list(string)
  default     = []
}

variable "default_capacity_provider_strategy" {
  description = "The capacity provider strategy to use by default for the cluster"
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = number
  }))
  default = []
}

variable "capacity_provider_name" {
  description = "Name of the capacity provider to associate with the cluster"
  type        = string
  default     = ""
}

variable "name_prefix" {
  description = "Prefix for the cluster name"
  type        = string
}
variable "asg_arn" {
  description = "ARN of the Auto Scaling Group to be used with the ECS Capacity Provider"
  type        = string
}

variable "use_existing_capacity_provider" {
  description = "Whether to use an existing capacity provider"
  type        = bool
  default     = false
}


