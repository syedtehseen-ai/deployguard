variable "vpc_id" {
  description = "The ID of the VPC coming from outputs of the vpc module through root main.tf"
  type        = string
}

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
variable "public_subnets_ids" {
  description = "Map of subnets IDs"
  type        = map(string)
}
variable "tags" {
  description = "Global tags for all resources"
  type        = map(string)
  default     = {}
}

variable "igw_id" {
  description = "The ID of the IGW"
  type        = string
}