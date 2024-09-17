variable "cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "enable_dns_hostnames" {
  description = "Whether or not DNS hostnames are enabled for the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Whether or not DNS support is enabled for the VPC."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
}

variable "azs_count" {
  description = "Number of AZs to cover in the VPC"
  type        = number
}

variable "azs_names" {
  description = "List of AZ names"
  type        = list(string)
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

variable "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  type        = list(string)
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "create_igw" {
  description = "Whether to create an Internet Gateway"
  type        = bool
  default     = true
}

variable "existing_internet_gateway_id" {
  description = "ID of an existing Internet Gateway to use"
  type        = string
  default     = ""
}

variable "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
