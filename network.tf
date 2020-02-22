# network.tf

resource "aws_vpc" "main"{
	cidr_block						= var.cidr_block 
	enable_dns_hostnames	= true
}	

resource "aws_subnet" "private"{
	vpc_id						      = aws_vpc.main.id
	cidr_block				      = cidrsubnet(var.cidr_block, 8, 0) 
	availability_zone	      = "${var.region}${var.zone}"
}

resource "aws_subnet" "egress"{
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, 1)
  availability_zone = "${var.region}${var.zone}"
}

resource "aws_route_table" "egress" {
  vpc_id            = aws_vpc.main.id
}

resource "aws_route_table_association" "egress"{
  subnet_id       = aws_subnet.egress.id
  route_table_id  = aws_route_table.egress.id
}

resource "aws_eip" "eip"{
  vpc = true 
}

resource "aws_internet_gateway" "gw" {
  vpc_id    = aws_vpc.main.id
}

resource "aws_nat_gateway" "nat"{
	subnet_id     = aws_subnet.egress.id
  allocation_id = aws_eip.eip.id
  depends_on    = [aws_internet_gateway.gw]
}

resource	"aws_route" "outbound"{
	route_table_id					= aws_vpc.main.main_route_table_id
	destination_cidr_block	= "0.0.0.0/0"
	nat_gateway_id					= aws_nat_gateway.nat.id
}

resource "aws_route" "egress" {
  route_table_id          = aws_route_table.egress.id
  destination_cidr_block  = "0.0.0.0/0"
  gateway_id              = aws_internet_gateway.gw.id
}

output "vpc_id"{
  value = aws_vpc.main.id
}

output "subnet"{
  value = aws_subnet.private
}

