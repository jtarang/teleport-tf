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

  #  Allow CoreDNS communication
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    self        = true
  }

}

resource "aws_security_group" "ad_nsg" {
  name        = "${var.user_prefix}-ad-domain-controller-nsg"
  description = "${var.user_prefix}: Security group for Active Directory Domain Controller"
  vpc_id      = var.vpc_id  # Replace with your actual VPC ID
  
  tags = merge(var.tags, {
    "Name"        = "${var.user_prefix}-ad-domain-controller-nsg"
  })

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
  
  # DNS
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "DNS"
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "DNS"
  }

  # LDAP SSL
  ingress {
    from_port   = 636
    to_port     = 636
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "LDAP SSL"
  }


  # LDAP GC SSL
  ingress {
    from_port   = 3269
    to_port     = 3269
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "LDAP GC SSL"
  }

  # W32Time
  ingress {
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "W32Time"
  }

}