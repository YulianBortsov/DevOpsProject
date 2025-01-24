locals {
    environment = "dev"
    region = "us-east-1"
    domain_name = "ybort.shop"
    project_name = "DevOpsProject"
    vpc_cidr = "10.0.0.0/16"
    db_name = "taskManagerDB"
    enable_nat_gateway = true
    single_nat_gateway = true
    enable_karpenter = true
    enable_argocd = true
    enable_aws_load_balancer_controller = true
    enable_external_secrets = true
    num_zones = 2
}