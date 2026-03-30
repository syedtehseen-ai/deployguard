# # PUB Subnet and its association with IGW
resource "aws_route_table" "pubroutes" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }
  tags = merge(
    var.tags,{ Name = "public-route"}
  )
}

resource "aws_route_table_association" "pubattach" {
  for_each = var.public_subnets_ids
  subnet_id      = each.value
  route_table_id = aws_route_table.pubroutes.id
}

# PVT Subnet and its association with NAT GW

resource "aws_route_table" "pvtroutes" {
  vpc_id = var.vpc_id
  for_each = var.natgw_id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = each.value
  } 
  tags = merge(
    var.tags,{ Name = "pvt-route"}
  )
}

resource "aws_route_table_association" "pvtattach" {
  for_each = var.private_subnet_natgw_map
  subnet_id      = var.private_subnets_ids[each.key]
  route_table_id = aws_route_table.pvtroutes[each.value].id
}
