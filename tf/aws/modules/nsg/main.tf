resource "aws_security_group" "ssh_only_nsg" {
  name        = "${var.user_prefix}-ssh-only-sg"
  description = "Security group that allows SSH only from my IP"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    "Name" = "${var.user_prefix}-nsg"
  })

  # Inbound rule: Allow SSH (port 22) only from the specified IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_external_ip}/32"] # Restrict access to the specified IP only
  }

  # Outbound rule: Allow all outbound traffic (default rule)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic to anywhere
  }
}
