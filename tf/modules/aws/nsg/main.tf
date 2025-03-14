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

resource "aws_security_group" "ad_nsg" {
  name        = "${var.user_prefix}-ad-domain-controller-nsg"
  description = "${var.user_prefix}: Security group for Active Directory Domain Controller"
  vpc_id      = var.vpc_id  # Replace with your actual VPC ID
  
  tags = merge(var.tags, {
    "Name"        = "${var.user_prefix}-ad-domain-controller-nsg"
  })

  # Allow DNS (UDP/TCP 53)
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Allow Kerberos authentication (TCP 88)
  ingress {
    from_port   = 88
    to_port     = 88
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
  
  # Allow LDAP (TCP 389) and Secure LDAP (TCP 636)
  ingress {
    from_port   = 389
    to_port     = 389
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
  ingress {
    from_port   = 636
    to_port     = 636
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Allow SMB file sharing (TCP 445)
  ingress {
    from_port   = 445
    to_port     = 445
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Allow RPC Endpoint Mapper (TCP 135)
  ingress {
    from_port   = 135
    to_port     = 135
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Allow Kerberos password changes (TCP/UDP 464)
  ingress {
    from_port   = 464
    to_port     = 464
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
  ingress {
    from_port   = 464
    to_port     = 464
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Allow Network Time Protocol (NTP) (UDP 123)
  ingress {
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Allow NetBIOS (UDP 138) - Only if needed
  ingress {
    from_port   = 138
    to_port     = 138
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Allow ephemeral ports for RPC and DCOM (TCP 49152-65535)
  ingress {
    from_port   = 49152
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["${var.my_external_ip}/32"] # Restrict access to the specified IP only
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }
}
