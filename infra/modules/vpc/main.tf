resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true # Required for EKS service discovery
  region = var.region

  tags = merge(
    var.tags,
    {Name = var.vpctag}
  )
}

resource "aws_internet_gateway" "internetgw" {
  vpc_id = aws_vpc.main.id
  region = var.region

  tags = merge(
    var.tags,{Name = var.igw_name}
  )
}