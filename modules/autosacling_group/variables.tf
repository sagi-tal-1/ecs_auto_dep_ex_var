variable "name_prefix" {
  description = "Prefix to use for resource names"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to launch resources in"
  type        = list(string)
}

variable "min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "launch_template_id" {
  description = "ID of the launch template to use"
  type        = string
}

variable "instance_name" {
  description = "Name to give the EC2 instance"
  type        = string
}

variable "desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "enabled" {
  description = "Whether to create the Auto Scaling Group"
  type        = bool
  default     = true
}
#  variable "asg_arn" {
#      description = "The ARN of the Auto Scaling Group"
#      type        = string
#    }