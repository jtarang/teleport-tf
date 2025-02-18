output "nsg_id" {
  value = aws_security_group.ssh_only_nsg.id
}

output "nsg_name" {
  value = aws_security_group.ssh_only_nsg.name
}

