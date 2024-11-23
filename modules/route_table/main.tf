resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.name}-public-rt"
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.internet_gateway_id
}

resource "aws_route_table_association" "public" {
  count          = length(var.subnet_ids)
  subnet_id      = var.subnet_ids[count.index]
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnet_ids)
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.name}-private-rt-${count.index + 1}"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_ids)
  subnet_id      = var.private_subnet_ids[count.index]
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route" "private_nat_gateway" {
  count          = length(var.private_subnet_ids)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.nat_gateway_id
}


