output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = aws_subnet.private[*].id
}

output "subnet_ids" {
  description = "IDs of all subnets."
  value       = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
}

output "subnet_count" {
  description = "Number of created subnets."
  value       = length(aws_subnet.public)
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = aws_route_table.private[*].id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = var.internet_gateway_id
}
