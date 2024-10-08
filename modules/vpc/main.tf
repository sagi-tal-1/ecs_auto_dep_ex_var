resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.name
  }
}

locals {
  vpc_id = var.existing_vpc_id != "" ? var.existing_vpc_id : aws_vpc.main.id
}

resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = local.vpc_id
  availability_zone       = var.availability_zones[count.index]
  cidr_block              = cidrsubnet(var.cidr_block, 8, count.index)
  map_public_ip_on_launch = var.map_public_ip_on_launch
  tags                    = { Name = "${var.name}-public-${var.availability_zones[count.index]}" }
}

resource "aws_subnet" "private" {
  count              = length(var.availability_zones)
  vpc_id             = local.vpc_id
  cidr_block         = cidrsubnet(var.cidr_block, 8, count.index + length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.name}-private-${var.availability_zones[count.index]}"
  }
}
