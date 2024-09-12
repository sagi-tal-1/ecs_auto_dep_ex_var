variable "az_count" {
     description = "Number of AZs to cover in a given region"
     type        = number
   }

   variable "public_subnet_ids" {
     description = "List of public subnet IDs"
     type        = list(string)
   }

   variable "name_prefix" {
     description = "Prefix to use for resource names"
     type        = string
   }

   variable "existing_eip_ids" {
     description = "List of existing Elastic IP IDs to use for NAT Gateways"
     type        = list(string)
     default     = []
   }

   variable "vpc_id" {
     description = "ID of the VPC"
     type        = string
   }

   variable "region" {
     description = "AWS region"
     type        = string
   }