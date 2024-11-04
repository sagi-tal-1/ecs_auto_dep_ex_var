
#moduls/ecs_launch_template/virabels.tf
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

variable "root_volume_size" {
  description = "The size of the root volume in GB"
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "The type of the root volume (gp2, gp3, io1, etc.)"
  type        = string
  default     = "gp3"
}

variable "additional_user_data" {
  description = "Additional user data script to run on instance launch"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to add to the launch template"
  type        = map(string)
  default     = {}
}


variable "log_file" {
  description = "Path to the log file for ECS user data script."
  type        = string
  default     = "/var/log/ecs/user_data.log"
}
variable "error_log" {
  description = "Path to the error log file for ECS user data script."
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ECS service"
  type        = list(string)
}


