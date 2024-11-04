#modules/ecs_node_role/variabels.tf

variable "role_name_prefix" {
  description = "Prefix for the ECS node role name."
  type        = string
}

variable "profile_name_prefix" {
  description = "Prefix for the ECS node instance profile name."
  type        = string
}

variable "enable_full_access" {
  description = "Whether to enable full access for the ECS node role."
  type        = bool
  default     = true
}

variable "additional_policies" {
  description = "List of additional policy ARNs to attach to the ECS node role."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}