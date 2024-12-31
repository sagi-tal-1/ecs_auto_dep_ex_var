variable "service_name" {
  type        = string
  description = "Name of the ECS service"
}

# variable "namespace_id" {
#   type        = string
#   description = "The ID of the namespace for service discovery"
# }

variable "environment" {
  type        = string
  description = "The environment (e.g., dev, prod)"
}

variable "vpc_id" {
  description = "The ID of the VPC for the private DNS namespace"
  type        = string
}