resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

     # Explicitly set these to null
  assign_generated_ipv6_cidr_block = null
  ipv6_ipam_pool_id                = null
  ipv6_netmask_length               = null
  instance_tenancy                  = "default"
  
  tags = {
    Name = var.name
  }
}

locals {
  vpc_id = var.existing_vpc_id != "" ? var.existing_vpc_id : aws_vpc.main.id
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = local.vpc_id
  availability_zone       = var.availability_zones[count.index]
  cidr_block              = cidrsubnet(var.cidr_block, 8, count.index)
  map_public_ip_on_launch = var.map_public_ip_on_launch
  tags                    = { Name = "${var.name}-public-${var.availability_zones[count.index]}" }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = local.vpc_id
  cidr_block        = cidrsubnet(var.cidr_block, 8, count.index + length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.name}-private-${var.availability_zones[count.index]}"
  }
}

# # VPC Peering Connection
# resource "aws_vpc_peering_connection" "private_subnets" {
#   peer_vpc_id = local.vpc_id
#   vpc_id      = local.vpc_id
  
#   auto_accept = true

#   tags = {
#     Name = "${var.name}-private-subnet-peering"
#   }
# }

# # Route Tables for Peered Subnets
# resource "aws_route_table" "private_0" {
#   vpc_id = aws_subnet.private[0].vpc_id

#   depends_on = [aws_subnet.private]

#   route {
#     cidr_block                = aws_subnet.private[1].cidr_block
#     vpc_peering_connection_id = aws_vpc_peering_connection.private_subnets.id
#   }

#   tags = {
#     Name = "${var.name}-private-route-0"
#   }
# }

# resource "aws_route_table" "private_1" {
#   vpc_id = aws_subnet.private[1].vpc_id

#   depends_on = [aws_subnet.private]

#   route {
#     cidr_block                = aws_subnet.private[0].cidr_block
#     vpc_peering_connection_id = aws_vpc_peering_connection.private_subnets.id
#   }

#   tags = {
#     Name = "${var.name}-private-route-1"
#   }
# }

# resource "aws_route_table_association" "private_0" {
#   subnet_id      = aws_subnet.private[0].id
#   route_table_id = aws_route_table.private_0.id

#   depends_on = [aws_route_table.private_0, aws_subnet.private]
# }

# resource "aws_route_table_association" "private_1" {
#   subnet_id      = aws_subnet.private[1].id
#   route_table_id = aws_route_table.private_1.id

#   depends_on = [aws_route_table.private_1, aws_subnet.private]
# }