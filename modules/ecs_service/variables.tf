
#moduls/ecs_service/virabels.tf
variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "cluster_id" {
  description = "ID of the ECS cluster"
  type        = string
}

# variable "ecs_cluster_id" {
#   description = "ID of the ECS cluster"
#   type        = string
# }

variable "task_definition_arn" {
  description = "ARN of the task definition"
  type        = string
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
}



variable "target_group_arn" {
  description = "ARN of the target group"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:elasticloadbalancing:[a-z0-9-]+:[0-9]+:targetgroup/[a-zA-Z0-9-]+/[a-zA-Z0-9]+$", var.target_group_arn))
    error_message = "The target_group_arn must be a valid AWS ARN for a target group."
  }
}

variable "container_name" {
  description = "Name of the container"
  type        = string
}

variable "capacity_provider_name" {
  description = "Name of the capacity provider"
  type        = string
}

# variable "vpc_id" {
#   description = "ID of the VPC where the ECS tasks will run"
#   type        = string
# }

variable "name_prefix" {
  description = "Prefix for the service name"
  type        = string
}

variable "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  type        = string
}

variable "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  type        = string
}

variable "security_group_id" {
  description = "ID of the security group for ECS tasks"
  type        = string
}

variable "nginx_port" {
  description = "Port number for Nginx container"
  type        = number

  validation {
    condition = (var.nginx_port > 0 && var.nginx_port <= 65535) || var.nginx_port == 80
    error_message = "The nginx_port must be 80 or between 1 and 65535."
  }
}

variable "nginx_server_name" {
  default = "localhost"
}

variable "nginx_root_path" {
  default = "/usr/share/nginx/html"
}

variable "retention_in_days" {
  description = "Retention period for the CloudWatch Log Group (in days)"
  type        = number
  default     = 1
}

variable "network_mode" {
  description = "Network mode of the task definition (awsvpc, bridge, host, or none)"
  type        = string
  default     = "bridge"
}

# Add the missing alb_listener_arn variable
# variable "alb_listener_arn" {
#   description = "ARN of the ALB listener"
#   type        = string
# }
# Add to your variables.tf
variable "alb_dns_name" {
  description = "DNS name of the ALB"
  type        = string
}
# variable "private_subnets" {
#   description = "List of private subnet IDs"
#   type        = list(string)
# }


# variable "public_subnet_ids" {
#   description = "List of public subnet IDs"
#   type        = list(string)
# }
# variable "security_group_id" {
#   description = "Security group ID for the ECS tasks"
#   type        = string
# }



variable "source_security_group_id" {
  description = "Security group ID for the ECS tasks"
  type        = string
}

# variable "environment" {
#   description = "for tag"
#   type        = string
# }

variable "enable_placement_constraints" {
  description = "Enable placement constraints for the ECS service"
  type        = bool
}