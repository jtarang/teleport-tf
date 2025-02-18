output "private_key_pem" {
  description = "The private key material of the SSH key pair"
  value       = tls_private_key.ec2_ssh_key.private_key_openssh
  sensitive   = true  # Mark as sensitive to avoid accidental exposure
}

output "public_key" {
  description = "The public key material of the SSH key pair"
  value       = tls_private_key.ec2_ssh_key.public_key_openssh
}

output "aws_key_pair_name" {
  description = "AWS key pair name that was uploaded"
  value       = aws_key_pair.aws_ec2_key_pair.key_name
}
