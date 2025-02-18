resource "tls_private_key" "ec2_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "aws_ec2_key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.ec2_ssh_key.public_key_openssh
  tags       = var.tags
}


# Write the private key to a file on the local machine
resource "local_file" "private_key" {
  filename = join("-", [var.key_name, tls_private_key.ec2_ssh_key.algorithm])  # Specify the desired file path here
  content  = tls_private_key.ec2_ssh_key.private_key_openssh
}

# Write the public key to a file on the local machine
resource "local_file" "public_key" {
  filename = join("-", [var.key_name, tls_private_key.ec2_ssh_key.algorithm, "public.pub"]) # Specify the desired file path here
  content  = tls_private_key.ec2_ssh_key.public_key_openssh
}