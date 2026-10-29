output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.this.cidr_block
}

output "availability_zones" {
  description = "Availability zones used by the subnets"
  value       = local.azs
}

output "public_subnet_ids" {
  description = "Public subnet IDs, ordered by AZ"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs, ordered by AZ"
  value       = aws_subnet.private[*].id
}

output "nat_public_ips" {
  description = "Elastic IPs used by the NAT gateway(s)"
  value       = aws_eip.nat[*].public_ip
}
