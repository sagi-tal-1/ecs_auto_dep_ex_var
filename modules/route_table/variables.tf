variable "vpc_id" {
  description = "ID of the VPC where the route tables will be created."
  type        = string
}

variable "name" {
  description = "Name prefix for the route tables."
  type        = string
}

variable "internet_gateway_id" {
  description = "ID of the internet gateway used in the public route."
  type        = string
}

variable "subnet_ids" {
  description = "List of public subnet IDs to associate with the public route table."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs to associate with the private route tables."
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  type        = string
}
variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}