resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  count             = var.subnet_public_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.env}-public-subnet"
  }
}

resource "aws_subnet" "private" {
  count             = var.subnet_private_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 2}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.env}-private-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_eip" "main" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }
    tags = {
        Name = "${var.env}-rt-public"
    }
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.main.id
    }
    tags = {
        Name = "${var.env}-rt-private"
    }
}

resource "aws_route_table_association" "public" {
    count = var.subnet_public_count
    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
    count = var.subnet_private_count
    subnet_id = aws_subnet.private[count.index].id
    route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "allow_ssh_http_icmp" {
  name        = "allow_ssh_http_icmp"
  description = "Allow_ssh_http_icmp inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "Allow HTTP, SSH, ICMP"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_http_icmp_ipv4" {
  for_each          = var.allowed_protocols_sg
  security_group_id = aws_security_group.allow_ssh_http_icmp.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = each.key
  ip_protocol       = each.value
  to_port           = each.key
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_ssh_http_icmp.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}