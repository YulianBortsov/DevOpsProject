locals {
  name   = "${var.environment}-${var.project_name}"
  region = var.region
  azs    = data.aws_availability_zones.available.names
  private_subnets = [
    for i, az in local.azs :
    cidrsubnet(var.vpc_cidr, 4, i * 2 + 1)
  ]
  public_subnets = [
    for i, az in local.azs :
    cidrsubnet(var.vpc_cidr, 4, i * 2)
  ]
  tags = {
    ManagedBy   = "Terraform"
    Environment = var.environment
    Project     = var.project_name
  }
}
data "aws_availability_zones" "available" {
  state = "available"
}
module "vpc" {
  source                  = "terraform-aws-modules/vpc/aws"
  version                 = "5.5.0"
  name                    = "${local.name}-vpc"
  cidr                    = var.vpc_cidr
  azs                     = local.azs
  private_subnets         = local.private_subnets
  public_subnets          = local.public_subnets
  map_public_ip_on_launch = true
  enable_nat_gateway      = var.enable_nat
  single_nat_gateway      = var.enable_nat
  enable_dns_hostnames    = true
  enable_dns_support      = true
  tags                    = local.tags
  public_subnet_tags = merge(
    {
      "kubernetes.io/role/elb"                    = "1"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    },
    var.publicEKS ? { "karpenter.sh/discovery" = var.cluster_name } : {}
  )

  private_subnet_tags = var.publicEKS ? {} : {
    "karpenter.sh/discovery" = var.cluster_name
  }
}
module "eks" {
  source                                   = "terraform-aws-modules/eks/aws"
  version                                  = "20.31.6"
  cluster_name                             = var.cluster_name
  cluster_version                          = var.cluster_version
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true
  subnet_ids                               = var.publicEKS ? slice(module.vpc.public_subnets, 0, 3) : slice(module.vpc.private_subnets, 0, 3)
  vpc_id                                   = module.vpc.vpc_id
  enable_irsa                              = true
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  # eks_managed_node_groups = {
  #   eks_nodes = {
  #     desired_size  = 2
  #     max_size      = 3
  #     min_size      = 1
  #     instance_type = ["t3.medium"]
  #     capacity_type = "ON_DEMAND"
  #     labels = {
  #       Environment = var.environment
  #     }
  #     tags = {
  #       Environment = var.environment
  #     }
  #   }
  # }
  node_security_group_additional_rules = {
    ingress_http = {
      description = "Allow HTTP inbound traffic"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      type        = "ingress"
      self        = true
    }
  }

  eks_managed_node_groups = {
    karpenter = {
      desired_size  = 1
      max_size      = 3
      min_size      = 1
      instance_type = ["t3.small"]
      capacity_type = "ON_DEMAND"
      taints = {
        addons = {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
      labels = {
        Environment = var.environment
      }
      tags = {
        Environment = var.environment
      }
    }
  }
  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }

  tags       = local.tags
  depends_on = [module.vpc]
}

