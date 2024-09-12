resource "aws_route_table_association" "public" {
  count          = var.subnet_count
  subnet_id      = var.subnet_ids[count.index]
  route_table_id = var.route_table_id
}
