   output "nat_gateway_id" {
     description = "ID of the NAT Gateway"
     value       = aws_nat_gateway.main.id
   }

   output "nat_gateway_public_ip" {
     description = "Public IP associated with the NAT Gateway"
     value       = aws_eip.nat.public_ip
   }

   output "eip_id" {
     description = "ID of the Elastic IP associated with the NAT Gateway"
     value       = aws_eip.nat.id
   }

 output "nat_gateway_private_ip" {
  description = "Private IP address of the NAT Gateway"
  value       = aws_nat_gateway.main.private_ip
}