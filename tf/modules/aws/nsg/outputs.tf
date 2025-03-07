output "nsg_id" {
  value = aws_security_group.nsg.id
}

output "nsg_name" {
  value = aws_security_group.nsg.name
}

output "ad_domain_controller_nsg_name" {
  value = aws_security_group.ad_nsg.name
  
}

output "ad_domain_controller_nsg_id" {
  value = aws_security_group.ad_nsg.id
}
