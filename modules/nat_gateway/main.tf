resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "${var.name_prefix}-eip-nat"
  }

  lifecycle {
    create_before_destroy = true
  }

  provisioner "local-exec" {
    when    = destroy
    command = "aws ec2 release-address --allocation-id ${self.id} || true"
  }

}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.public_subnet_ids[0]

  tags = {
    Name = "${var.name_prefix}-nat-gw"
  }
depends_on = [aws_eip.nat]

  lifecycle {
    create_before_destroy = true
  }
}