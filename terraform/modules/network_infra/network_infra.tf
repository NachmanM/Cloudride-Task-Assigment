resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
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
    Name = "${var.resource_name}-public-subnet"
  }
}

resource "aws_subnet" "private" {
  count             = var.subnet_private_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 2}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.resource_name}-private-subnet"
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
    Name = "${var.resource_name}-rt-public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.main.id
  }
  tags = {
    Name = "${var.resource_name}-rt-private"
  }
}

resource "aws_route_table_association" "public" {
  count          = var.subnet_public_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = var.subnet_private_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "tasks" {
  name        = "tasks"
  description = "tasks inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "Allow HTTP, SSH, ICMP"
  }
  depends_on = [aws_security_group.alb]
}

resource "aws_vpc_security_group_ingress_rule" "tasks_ipv4" {
  for_each          = var.allowed_protocols_sg
  security_group_id = aws_security_group.tasks.id
  from_port         = each.key
  ip_protocol       = each.value
  to_port           = each.key
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.tasks.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


resource "aws_security_group" "alb" {
  name        = "${var.resource_name}-alb"
  description = "alb inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "alb_ipv4" {
  for_each          = var.allowed_protocols_sg_alb
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = each.key
  ip_protocol       = each.value
  to_port           = each.key
}

resource "aws_vpc_security_group_egress_rule" "alb_egress_ipv4" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}