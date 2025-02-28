resource "aws_security_group" "nsg" {
  name        = "${var.user_prefix}-sg"
  description = "${var.user_prefix}: Network Security Group"
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
    #  Allow Kubernetes API access from worker nodes
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Or limit it to EKS control plane IPs
  }

  # Allow worker nodes to communicate with each other
  ingress {
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["${var.my_external_ip}/32"] # Restrict access to the specified IP only
  }

  # Postgres Test
  # ingress {
  #   from_port   = 5432
  #   to_port     = 5432
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }


  #  Allow CoreDNS communication
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    self        = true
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
  }
}