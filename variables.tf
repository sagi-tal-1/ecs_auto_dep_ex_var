variable "capacity_provider_name" {
  description = "The name of the capacity provider for the ECS service"
  type        = string
  default     = "demo-ecs-ec2" # Add a default value if appropriate
}
# variable "target_group_arn" {
#   description = "The ARN of the target group to associate with the ECS service"
#   type        = string
# }

# variable "task_definition_arn" {
#   description = "The ARN of the ECS task definition"
#   type        = string
# }

variable "desired_count" {
  description = "The desired number of tasks for the ECS service"
  type        = number
  default     = 1
}

# # Assigning the subnet IDs from the VPC module output to a variable
# variable "subnet_ids" {
#   description = "The list of subnet IDs for the ECS service"
#   type        = list(string)
#   default     = module.vpc.subnet_ids
# }

variable "task_cpu" {
  description = "The amount of CPU to allocate for the task"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "The amount of memory to allocate for the task"
  type        = string
  default     = "512"
}

variable "example_env_value" {
  description = "An example environment variable value"
  type        = string
  default     = "example"
}

variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1" # Change this to your desired region
}

variable "existing_vpc_id" {
  description = "ID of an existing VPC to use (leave blank to create a new VPC)"
  type        = string
  default     = ""
}

variable "ecs_service_count" {
  description = "Number of ECS services to create"
  type        = number
  default     = 1
}



variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "demo"
}


variable "cloudwatch_logs_name_prefix" {
  description = "Prefix for the CloudWatch Log Group name"
  type        = string
  default     = "my-log-group-"
}

variable "cloudwatch_logs_retention_days" {
  description = "Number of days to retain logs in the CloudWatch Log Group"
  type        = number
  default     = 1
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "demo" # You can change this default value
}

