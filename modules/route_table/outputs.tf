output "route_table_association_ids" {
  description = "IDs of the route table associations"
  value       = aws_route_table_association.public[*].id
}
