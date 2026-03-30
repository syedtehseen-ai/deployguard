variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}
variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}
variable "vpctag" {
  description = "Name tag for the VPC"
  type        = string
}

variable "igw_name" {
  description = "Name of the Internet Gateway"
  type        = string
}

# variable "vpc_id" {
#   description = "The ID of the VPC coming from outputs of the vpc module through root main.tf"
#   type        = string
# }

variable "pubsubnets" {
  description = "Map of subnets for all environments"
  type        = map(object({ 
    cidr = string
    pubaz = string
  }))
}

variable "pvtsubnets" {
  description = "Map of subnets for all environments"
  type        = map(object({ 
    cidr = string
    pvtaz = string
  }))
}

variable "tags" {
  description = "Global tags for all resources"
  type        = map(string)
  default     = {}
}

# variable "igw_id" {
#   description = "The ID of the IGW"
#   type        = string
# }

# variable "public_subnets_ids" {
#   description = "Map of subnets IDs"
#   type        = map(string)
# }
# variable "natgw_id" {
#   description = "The ID of the Nat GW"
#   type        = map(string)
# }
variable "private_subnet_natgw_map" {
  description = "Map private subnet key to NAT Gateway key"
  type        = map(string)
}
# variable "private_subnets_ids" {
#   description = "Map of subnets IDs"
#   type        = map(string)
# }