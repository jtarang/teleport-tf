# Create the VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    "Name" = "${var.user_prefix}-vpc"
  })
}

# Create Public Subnets for 2 AZs dynamically
resource "aws_subnet" "public" {
  for_each = { for idx, az in var.availability_zones : 
    "${idx}-public" => {
      az = az
      cidr = element(var.public_subnet_cidrs, idx)
    }
  }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(var.tags, {
    "Name" = "${var.user_prefix}-public-subnet-${each.value.az}"
  })
}

# Create Private Subnets for 2 AZs dynamically
resource "aws_subnet" "private" {
  for_each = { for idx, az in var.availability_zones : 
    "${idx}-private" => {
      az = az
      cidr = element(var.private_subnet_cidrs, idx)
    }
  }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.tags, {
    "Name" = "${var.user_prefix}-private-subnet-${each.value.az}"
  })
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = var.tags
}

# Create NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id

  # Reference the first public subnet dynamically
  subnet_id = values(aws_subnet.public)[0].id 

  tags = {
    Name = "${var.user_prefix}-nat-gateway"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    "Name" = "${var.user_prefix}-internet-gateway"
  })
}

# Create a Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Add route to internet gateway (0.0.0.0/0 -> IGW)
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    "Name" = "${var.user_prefix}-public-route-table"
  })
}

# Associate the route table with the public subnets
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Create a Route Table for Private Subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    "Name" = "${var.user_prefix}-private-route-table"
  })
}

# Create a route for private subnets to the NAT gateway
resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# Associate the route table with the private subnets
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
