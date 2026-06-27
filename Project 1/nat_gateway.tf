# 1. ELASTIC IPs ΓΙΑ ΤΑ NAT GATEWAYS

resource "aws_eip" "nat_eip" {
  count  = length(var.availability_zones)
  domain = "vpc"

  tags = {
    Name = "Project-1-NAT-EIP-${count.index == 0 ? "A" : "B"}"
  }
}

# 2. AWS NAT GATEWAYS (High Availability / Multi-AZ)

resource "aws_nat_gateway" "nat_gateways" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id 

  tags = {
    Name = "Project-1-NAT-Gateway-${count.index == 0 ? "A" : "B"}"
  }

  depends_on = [aws_internet_gateway.igw]
}

# 3. PRIVATE ROUTES NAT Gateways

resource "aws_route" "private_nat_route_a" {
  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateways[0].id
}

resource "aws_route" "private_nat_route_b" {
  route_table_id         = aws_route_table.private[1].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateways[1].id
}