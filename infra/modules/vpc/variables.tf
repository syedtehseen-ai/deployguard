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
variable "tags" {
  description = "Global tags for all resources"
  type        = map(string)
  default     = {}
}
variable "igw_name" {
  description = "Name of the Internet Gateway"
  type        = string
}
