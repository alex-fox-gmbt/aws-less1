
# VPC
resource "aws_vpc" "main" {
  cidr_block = "172.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = merge(var.tags, { Name = "main" }) 
}


# SUBNETS
resource "aws_subnet" "sub_pub1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.0.0.0/24"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = true

  tags = merge(var.tags, { Name = "pub1" }) 
}

resource "aws_subnet" "sub_pub2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.0.1.0/24"
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = true

  tags = merge(var.tags, { Name = "pub2" }) 
}


# DB SUBNET
resource "aws_db_subnet_group" "db_subnet" {
  name = "db_subnet"
  subnet_ids = [aws_subnet.sub_pub1.id,
                aws_subnet.sub_pub2.id]

  tags = merge(var.tags, { Name = "db_subnet" }) 
}


# IGW
resource "aws_internet_gateway" "vpc_gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, { Name = "main_gw" }) 
}


# ROUTING TABLES
resource "aws_route_table" "pub_gw" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_gw.id
  }

  tags = merge(var.tags, { Name = "pub_gw" }) 
}

resource "aws_route_table_association" "pub1_gw" {
  subnet_id = aws_subnet.sub_pub1.id
  route_table_id = aws_route_table.pub_gw.id
}

resource "aws_route_table_association" "pub2_gw" {
  subnet_id = aws_subnet.sub_pub2.id
  route_table_id = aws_route_table.pub_gw.id
}