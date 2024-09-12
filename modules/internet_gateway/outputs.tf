output "internet_gateway_id" {
  description = "ID of the internet gateway."
  value       = aws_internet_gateway.main.id
}

output "eip_ids" {
  description = "IDs of the Elastic IPs."
  value       = aws_eip.main[*].id
}
