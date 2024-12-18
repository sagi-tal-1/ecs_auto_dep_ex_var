
# modules/alb/virabels.tf
variable "name_prefix" {
  description = "Prefix to use for resource names"
  type        = string
}

variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where resources will be created"
  type        = string
}

# variable "subnet_ids" {
#   description = "List of subnet IDs where the ALB will be placed"
#   type        = list(string)
# }

variable "nginx_port" {
  description = "Port number for Nginx container"
  type        = number
}

variable "nodejs_port" {
  description = "Port number for Node.js application"
  type        = number
  default     = 3000
}

# variable "nodejs_health_check_path" {
#   description = "Health check path for Node.js application"
#   type        = string
#   default     = "/health"
# }
# Add variables block (add to your variables.tf file)
variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ECS service"
  type        = list(string)
}


# variable "enable_asg_target_group_attachment" {
#   description = "Name of the Application Load Balancer"
#   type        = string
# }
variable "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group to attach to the target group"
  type        = string
  default     = null  # Make it optional
}


variable "static_ec2_instance_ids" {
  description = "List of EC2 instance IDs to attach to the target group"
  type        = list(string)
  default     = []
}


variable "private_subnet_cidrs" {
  type = list(string)
  description = "List of private subnet CIDRs passed from the VPC module"
}