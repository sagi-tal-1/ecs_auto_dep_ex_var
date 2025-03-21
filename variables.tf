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

variable "log_file" {
  description = "Path to the log file for ECS user data script."
  type        = string
  default     = "/var/log/ecs/user_data.log"
}


variable "container_name" {
  description = "The base name for the container"
  type        = string
  default     = "my-container"
}


variable "nodejs_container_name" {
  description = "Name of the Node.js container"
  type        = string
  default     = "nodejs-app"
}

# variable "vpc_id" {
#   description = "ID of the VPC where the service discovery namespace will be created"
#   type        = string
# }



# Update variables.tf in the root directory - Add these variables


variable "nodejs_image" {
  description = "Docker image for Node.js application"
  type        = string
  default     = "node:14"
}

variable "nodejs_port" {
  description = "Port for Node.js application"
  type        = number
  default     = 3000
}

variable "nodejs_desired_count" {
  description = "Desired count of Node.js tasks"
  type        = number
  default     = 1
}
# Root variables.tf

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = "ECS"
}

variable "task_count" {
  type        = number
  description = "Number of tasks to run"
  default     = 2
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}



variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

output "container_name" {
  value = module.ecs_task_definition.container_name
}