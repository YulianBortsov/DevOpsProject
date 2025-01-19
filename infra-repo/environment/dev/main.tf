terraform {
  backend "s3" {
    bucket = "tf-state-bucket-drills"
    key    = "terraform/state-infra-repo"
    region = "us-east-1"
  }
}

# module "platform" {
#   source = "../../eks-platform"
#   region = "us-east-1"

#   environment  = "dev"
#   project_name = "first-ingra-project"

#   cluster_name    = "my-eks-cluster"
#   cluster_version = "1.31"
#   publicEKS       = true

#   vpc_cidr    = "192.168.0.0/16"
#   enable_nat  = false
#   domain_name = "ybort.shop"

#   nginx_controller_service_type = "ClusterIP"
# }

module "platform_v1" {
  source             = "../../eks_platform_v1"
  region             = "us-east-1"
  aws_account_id     = "640168420071"
  domain_name        = "ybort.shop"
  project_name       = "DevOpsProject"
  environment        = "dev"
  vpc_cidr           = "10.0.0.0/16"
  enable_nat_gateway = true
  single_nat_gateway = true
  enable_karpenter   = true
  eks_managed_node_groups = {
    eks_nodes = {
      desired_size  = 2
      max_size      = 10
      min_size      = 1
      instance_type = ["t3.medium"]
      capacity_type = "ON_DEMAND"
    }
  }
}
