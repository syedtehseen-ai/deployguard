# Return a map: { public01 = "subnet-0abc...", public02 = "subnet-0def..." }
output "public_subnets_ids" {
  value = { for k, s in aws_subnet.pubsubnets : k => s.id }
}

output "private_subnets_ids" {
  value = { for k, s in aws_subnet.pvtsubnets : k => s.id }
}

output "natgw_id" {
  value = { for k, v in aws_nat_gateway.natgw : k => v.id }
}