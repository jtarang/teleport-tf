output "vpc_id" {
  value = aws_vpc.main.id
}

# Output for Public Subnet IDs
output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = [for subnet in aws_subnet.public : subnet.id]
}

# Output for Private Subnet IDs
output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "cidr_block" {
  description = "VPC CIDR Block"
  value = aws_vpc.main.cidr_block
}