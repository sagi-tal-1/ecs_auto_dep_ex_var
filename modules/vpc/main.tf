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
  count                   = var.azs_count
  vpc_id                  = local.vpc_id
  availability_zone       = var.azs_names[count.index]
  cidr_block              = cidrsubnet(var.cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.name}-public-${var.azs_names[count.index]}" }
}

resource "aws_subnet" "private" {
  count             = var.azs_count
  vpc_id            = local.vpc_id
  cidr_block        = cidrsubnet(var.cidr_block, 8, count.index + var.azs_count)
  availability_zone = var.azs_names[count.index]

  tags = {
    Name = "${var.name}-private-${count.index + 1}"
  }
}

resource "aws_route_table" "private" {
  count  = var.azs_count
  vpc_id = local.vpc_id

  tags = {
    Name = "${var.name}-private-rt-${count.index + 1}"
  }
}

resource "aws_route_table_association" "private" {
  count          = var.azs_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-public-rt"
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.internet_gateway_id
}







