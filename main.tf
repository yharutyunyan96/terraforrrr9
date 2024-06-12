
locals {
  azs = data.aws_availability_zones.available.names
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "custom-vpc-01" {
  cidr_block            = var.vpc_cidr
  instance_tenancy      = "default"
  enable_dns_hostnames  = true
  enable_dns_support    = true

  tags = {
    Name = "custom-vpc-01"
  }
}

resource "aws_internet_gateway" "sc_internet_gateway" {
  vpc_id = aws_vpc.custom-vpc-01.id

  tags = {
    Name = "smartcode-igw"
  }
}

resource "aws_route_table" "sc_public_rt" {
  vpc_id = aws_vpc.custom-vpc-01.id

  tags = {
    Name = "sc_public_rt"
  }
}

resource "aws_route" "default_rout" {
  route_table_id          = aws_route_table.sc_public_rt.id
  destination_cidr_block  = "0.0.0.0/0"
  gateway_id              = aws_internet_gateway.sc_internet_gateway.id
}

resource "aws_default_route_table" "sc_private_rt" {
  default_route_table_id  = aws_vpc.custom-vpc-01.default_route_table_id

  tags = {
    Name = "sc_private_rt"
  }
}


resource "aws_subnet" "sc_public_subnet" {
  count                     = 2
  vpc_id                    = aws_vpc.custom-vpc-01.id
  cidr_block                = var.public_subnets[count.index]
  map_public_ip_on_launch   = true
  availability_zone         = local.azs[count.index]

  tags = {
    Name = "sc_public_subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "sc_private_subnet" {
  count = 2
  vpc_id                  = aws_vpc.custom-vpc-01.id
  cidr_block              = var.private_subnets[count.index]
  map_public_ip_on_launch = false
  availability_zone       = local.azs[count.index]

  tags = {
    Name = "sc_private_subnet-${count.index + 1}"
  }
}

resource "aws_route_table_association" "sc_public_assoc" {
  count           = var.num_public_subnets
  subnet_id       = aws_subnet.sc_public_subnet[count.index].id
  route_table_id  = aws_route_table.sc_public_rt.id
}


# Security groups
resource "aws_security_group" "sc_sg" {
  name        = "public_secgroup"
  description = "security group for public instances Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.custom-vpc-01.id

  tags = {
    Name = "public sg"
  }
}

resource "aws_security_group_rule" "ingress_all" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = [var.access_ip, var.cloud9_ip]
  security_group_id = aws_security_group.sc_sg.id
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sc_sg.id
}
