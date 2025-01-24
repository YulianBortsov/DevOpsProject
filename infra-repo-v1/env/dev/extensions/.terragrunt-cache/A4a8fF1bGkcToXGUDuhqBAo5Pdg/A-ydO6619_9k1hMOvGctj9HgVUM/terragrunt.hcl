include "root" {
  path = find_in_parent_folders("root.hcl")
}
dependency "base" {
    config_path = "../base"
}
terraform {
  source = find_in_parent_folders("/modules/extensions")
} 
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}
inputs = {
  cluster_name = dependency.base.outputs.cluster_name
    region       = local.env_vars.locals.region
    environment  = local.env_vars.locals.environment
    project_name = local.env_vars.locals.project_name
    domain_name  = local.env_vars.locals.domain_name
    enable_argocd = local.env_vars.locals.enable_argocd
    enable_aws_load_balancer_controller = local.env_vars.locals.enable_aws_load_balancer_controller 
    enable_external_secrets = local.env_vars.locals.enable_external_secrets
    cluster_version =  dependency.base.outputs.cluster_version
    cluster_endpoint = dependency.base.outputs.cluster_endpoint
    cluster_oidc_provider_arn = dependency.base.outputs.cluster_oidc_provider_arn
    vpc_id = dependency.base.outputs.vpc_id
    cluster_certificate_authority_data = dependency.base.outputs.cluster_certificate_authority_data
}