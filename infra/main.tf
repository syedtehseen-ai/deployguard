############################################################
#  VPC Module
############################################################
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr = var.vpc_cidr
  tags     = var.tags
  vpctag   = var.vpctag
  region   = var.region
  igw_name = var.igw_name
}

############################################################
# Subnets Module
############################################################
module "subnets" {
  source     = "./modules/subnets"
  pubsubnets = var.pubsubnets
  pvtsubnets = var.pvtsubnets
  public_subnets_ids = module.subnets.public_subnets_ids
  vpc_id    = module.vpc.vpc_id
  tags      = var.tags
  igw_id    = module.vpc.igw_id
}

############################################################
# Route Tables Module
############################################################
module "route_tables" {
  source                   = "./modules/routes"
  vpc_id                   = module.vpc.vpc_id
  igw_id                   = module.vpc.igw_id
  natgw_id                 = module.subnets.natgw_id
  public_subnets_ids       = module.subnets.public_subnets_ids  # list of public subnet IDs
  private_subnets_ids      = module.subnets.private_subnets_ids # list of private subnet IDs
  private_subnet_natgw_map = var.private_subnet_natgw_map       # from dev.tfvars
  tags                     = var.tags
}