variable "vpc_id" {
  description = "ID of the VPC where the internet gateway will be attached."
  type        = string
}

variable "name" {
  description = "Name tag for the internet gateway."
  type        = string
}

variable "azs_count" {
  description = "Number of availability zones to use for Elastic IPs."
  type        = number
}

variable "azs_names" {
  description = "List of availability zone names for Elastic IPs."
  type        = list(string)
}
