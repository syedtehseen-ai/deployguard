variable "env_name" {
  description = "The name of the env"
  type        = string
  default = "dev"
}

variable "private_subnets_ids" {
  description = "Map of subnets IDs"
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

variable "tags" {
  description = "Global tags for all resources"
  type        = map(string)
  default     = {}
}

variable "desired_capacity" {}
variable "min_capacity" {}
variable "max_capacity" {}
variable "instance_type" {}
variable "vpc_id" {
  description = "The ID of the VPC coming from outputs of the vpc module through root main.tf"
  type        = string
}
variable "key_name" {}
variable "public_key_path" {}