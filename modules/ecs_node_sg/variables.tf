variable "name_prefix" {
  description = "Prefix for the ECS node security group name."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the security group will be created."
  type        = string
}




variable "alb_security_group_id" {
  description = "The ID of the ALB security group"
  type        = string
}

variable "nginx_port" {
  description = "Port number for Nginx container"
  type        = number
}

variable "node_port" {
  description = "Port number for Node.js container"
  type        = number
}


