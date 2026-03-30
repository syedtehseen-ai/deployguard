resource "aws_subnet" "pubsubnets" {
    for_each = var.pubsubnets
    vpc_id = var.vpc_id
    cidr_block = each.value.cidr
    availability_zone = each.value.pubaz
    map_public_ip_on_launch = true
    tags = merge(var.tags,{Name="${each.key}-subnet"})
}

resource "aws_subnet" "pvtsubnets" {
    for_each = var.pvtsubnets
    vpc_id = var.vpc_id
    cidr_block = each.value.cidr
    availability_zone = each.value.pvtaz
    tags = merge(var.tags,{Name="${each.key}-subnet"})
}

# EIP for NAT GW for Public Subnet
resource "aws_eip" "nateip" {
    for_each = var.public_subnets_ids
    domain = "vpc"
    tags = merge(var.tags,{Name = "eip-${each.key}"})
}

resource "aws_nat_gateway" "natgw" {
    for_each = var.public_subnets_ids
    allocation_id = aws_eip.nateip[each.key].id
    subnet_id = each.value
    tags = {
    Name = "gw-NAT"
    }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [var.igw_id] 
}