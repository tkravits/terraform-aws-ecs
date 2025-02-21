# --- VPC ---

data "aws_availability_zones" "available" { state = "available" }

# Select two availability zones from the available list based on the provider's AWS region
locals {
  azs_count = 2
  azs_names = data.aws_availability_zones.available.names
}

# Create the VPC resource with DNS hostnames and support enabled
resource "aws_vpc" "main" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "demo-vpc" }
}

# Create two public subnets, one in each availability zone
resource "aws_subnet" "public" {
  count                   = local.azs_count
  vpc_id                  = aws_vpc.main.id
  availability_zone       = local.azs_names[count.index]
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, 10 + count.index) # Creates /24 subnets
  map_public_ip_on_launch = true
  tags                    = { Name = "demo-public-${local.azs_names[count.index]}" }
}

# --- Internet Gateway ---

# Create an internet gateway to allow internet access for resources in the VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "demo-igw" }
}

# Allocate two Elastic IPs, typically for NAT Gateways (not created here)
resource "aws_eip" "main" {
  count      = local.azs_count
  depends_on = [aws_internet_gateway.main]
  tags       = { Name = "demo-eip-${local.azs_names[count.index]}" }
}

# --- Public Route Table ---

# Create a route table for public subnets with a default route to the internet gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "demo-rt-public" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

# Associate each public subnet with the public route table to enable internet access
resource "aws_route_table_association" "public" {
  count          = local.azs_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
