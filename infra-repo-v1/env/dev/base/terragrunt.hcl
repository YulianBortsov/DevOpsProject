include "root" {
  path = find_in_parent_folders("root.hcl")
}
terraform {
  source = find_in_parent_folders("/modules/base")
}
locals {
    env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}
inputs = {
   region             = local.env_vars.locals.region 
   environment        = local.env_vars.locals.environment
   num_zones          = local.env_vars.locals.num_zones
   project_name       = local.env_vars.locals.project_name
   vpc_cidr           = local.env_vars.locals.vpc_cidr
   db_name            = local.env_vars.locals.db_name
   enable_karpenter   = local.env_vars.locals.enable_karpenter
   enable_nat_gateway = local.env_vars.locals.enable_nat_gateway
   single_nat_gateway = local.env_vars.locals.single_nat_gateway
}