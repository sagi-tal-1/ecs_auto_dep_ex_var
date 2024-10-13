variable "cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones for the VPC"
  type        = list(string)
}

variable "existing_vpc_id" {
  description = "ID of an existing VPC to use (leave blank to create a new VPC)"
  type        = string
  default     = ""
}

variable "map_public_ip_on_launch" {
  description = "Specify true to indicate that instances launched into the subnet should be assigned a public IP address"
  type        = bool
  default     = true
}

