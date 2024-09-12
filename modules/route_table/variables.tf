variable "vpc_id" {
  description = "ID of the VPC where the route table will be created."
  type        = string
}

variable "name" {
  description = "Name tag for the route table."
  type        = string
}

variable "internet_gateway_id" {
  description = "ID of the internet gateway used in the route."
  type        = string
}

variable "subnet_count" {
  description = "Number of subnets to associate with the route table."
  type        = number
}

variable "subnet_ids" {
  description = "List of subnet IDs to associate with the route table."
  type        = list(string)
}

variable "route_table_id" {
  description = "ID of the public route table"
  type        = string
}