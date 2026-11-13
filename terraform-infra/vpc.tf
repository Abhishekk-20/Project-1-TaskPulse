provider "aws" {
  region = "ap-south-1"
}

# 1. The VPC
resource "aws_vpc" "taskpulse_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "taskpulse-vpc"
  }
}

# 2. Public Subnets (Edge Tier for ALBs & NAT Gateways)
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.taskpulse_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "taskpulse-public-ap-south-1a"
    "kubernetes.io/role/elb" = "1" # Required for EKS public load balancers
  }
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.taskpulse_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "taskpulse-public-ap-south-1b"
    "kubernetes.io/role/elb" = "1"
  }
}

# 3. Private Subnets (Application Tier for EKS & Flask/React Pods)
resource "aws_subnet" "private_az1" {
  vpc_id            = aws_vpc.taskpulse_vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name                              = "taskpulse-private-ap-south-1a"
    "kubernetes.io/role/internal-elb" = "1" # Required for EKS internal load balancers
  }
}

resource "aws_subnet" "private_az2" {
  vpc_id            = aws_vpc.taskpulse_vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name                              = "taskpulse-private-ap-south-1b"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# 4. Isolated Subnets (Data Tier for Amazon RDS PostgreSQL)
resource "aws_subnet" "isolated_az1" {
  vpc_id            = aws_vpc.taskpulse_vpc.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "taskpulse-isolated-ap-south-1a"
  }
}

resource "aws_subnet" "isolated_az2" {
  vpc_id            = aws_vpc.taskpulse_vpc.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "taskpulse-isolated-ap-south-1b"
  }
}

# 5. Internet Gateway (For Public Subnets)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.taskpulse_vpc.id

  tags = {
    Name = "taskpulse-igw"
  }
}

# 6. NAT Gateway (For Private Subnets outbound internet)
# Note: For production, you typically provision one NAT Gateway per AZ. 
# We are using one here to optimize costs while maintaining the architecture.
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_az1.id

  tags = {
    Name = "taskpulse-nat"
  }
  depends_on = [aws_internet_gateway.igw]
}

# 7. Route Tables
# Public Route Table (Routes to IGW)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.taskpulse_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "taskpulse-public-rt" }
}

resource "aws_route_table_association" "public_az1_assoc" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "public_az2_assoc" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public_rt.id
}

# Private Route Table (Routes to NAT Gateway)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.taskpulse_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "taskpulse-private-rt" }
}

resource "aws_route_table_association" "private_az1_assoc" {
  subnet_id      = aws_subnet.private_az1.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "private_az2_assoc" {
  subnet_id      = aws_subnet.private_az2.id
  route_table_id = aws_route_table.private_rt.id
}

# Isolated Route Table (No internet route)
resource "aws_route_table" "isolated_rt" {
  vpc_id = aws_vpc.taskpulse_vpc.id
  tags   = { Name = "taskpulse-isolated-rt" }
}

resource "aws_route_table_association" "isolated_az1_assoc" {
  subnet_id      = aws_subnet.isolated_az1.id
  route_table_id = aws_route_table.isolated_rt.id
}
resource "aws_route_table_association" "isolated_az2_assoc" {
  subnet_id      = aws_subnet.isolated_az2.id
  route_table_id = aws_route_table.isolated_rt.id
}

# 8. Stateless Network Access Control List (NACL) for Isolated Data Tier
resource "aws_network_acl" "isolated_nacl" {
  vpc_id     = aws_vpc.taskpulse_vpc.id
  subnet_ids = [aws_subnet.isolated_az1.id, aws_subnet.isolated_az2.id]

  # Allow inbound traffic ONLY from the Private Subnets on PostgreSQL port 5432
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.10.0/24" # Private AZ1
    from_port  = 5432
    to_port    = 5432
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "10.0.11.0/24" # Private AZ2
    from_port  = 5432
    to_port    = 5432
  }

  # Allow outbound ephemeral ports back to the Private Subnets
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.10.0/24"
    from_port  = 1024
    to_port    = 65535
  }
  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "10.0.11.0/24"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "taskpulse-isolated-nacl"
  }
}
