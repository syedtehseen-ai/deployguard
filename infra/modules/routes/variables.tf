
variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "igw_id" {
  description = "The ID of the IGW"
  type        = string
}
variable "tags" {
  description = "Global tags for all resources"
  type        = map(string)
  default     = {}
}
variable "public_subnets_ids" {
  description = "Map of subnets IDs"
  type        = map(string)
}
variable "natgw_id" {
  description = "The ID of the Nat GW"
  type        = map(string)
}
variable "private_subnet_natgw_map" {
  description = "Map private subnet key to NAT Gateway key"
  type        = map(string)
}
variable "private_subnets_ids" {
  description = "Map of subnets IDs"
  type        = map(string)
}