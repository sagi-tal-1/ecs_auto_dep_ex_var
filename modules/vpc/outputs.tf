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

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "availability_zones" {
  description = "List of AZs where subnets are created"
  value       = var.availability_zones
}

output "private_subnet_cidrs" {
  value = aws_subnet.private[*].cidr_block
  description = "List of private subnet CIDRs"
}

output "private_subnet_a" {
  description = "Private subnet in AZ A"
  value = tolist([for subnet in aws_subnet.private : subnet.id if subnet.availability_zone == var.availability_zones[0]])
}

output "private_subnet_b" {
  description = "Private subnet in AZ B"
  value = tolist([for subnet in aws_subnet.private : subnet.id if subnet.availability_zone == var.availability_zones[1]])
}
