variable "name_prefix" {
  description = "Prefix for the launch template name."
  type        = string
}

variable "ami_id" {
  description = "The AMI ID to use for the launch template."
  type        = string
}

variable "instance_type" {
  description = "The instance type to use for the launch template."
  type        = string
}

variable "security_group_id" {
  description = "The security group ID to associate with the launch template."
  type        = string
}

variable "iam_instance_profile_arn" {
  description = "The ARN of the IAM instance profile to associate with the launch template."
  type        = string
}

variable "cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "key_name" {
  description = "The name of the key pair to use for SSH access"
  type        = string
}

variable "log_group_name" {
  description = "The name of the CloudWatch log group"
  type        = string
}

variable "log_stream_name" {
  description = "The prefix for the CloudWatch log stream"
  type        = string
  default     = "ecs"
}