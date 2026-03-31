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

variable "private_subnet_natgw_map" {
  description = "Map private subnet key to NAT Gateway key"
  type        = map(string)
}


variable "eks_version" {
  description = "The name of the env"
  type        = string
}
variable "cluster_name" {
     description = "The name of the cluster"
  type        = string
}

variable "instance_type" {}
variable "desired_capacity" {}
variable "min_capacity" {}
variable "max_capacity" {}
variable "key_name" {}
variable "public_key_path" {}
variable "env_name" {}