module "eks" {
  source                                   = "terraform-aws-modules/eks/aws"
  version                                  = "~> 20.24"
  cluster_name                             = local.name
  cluster_version                          = "1.30"
  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access           = true
  vpc_id                                   = module.vpc.vpc_id
  subnet_ids                               = module.vpc.private_subnets
  # create_cluster_security_group            = var.enable_karpenter ? false : true

  eks_managed_node_groups = var.enable_karpenter ? {} : var.eks_managed_node_groups

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    drachtio_all = {
      protocol                      = "-1"
      from_port                     = 53
      to_port                       = 53
      type                          = "ingress"
      source_cluster_security_group = true
    }

    pod_access = {
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      cidr_blocks = ["${var.vpc_cidr}"]
    }

    egress_all = {
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    cluster_nodes_incoming = {
      protocol                      = "tcp"
      from_port                     = 1025
      to_port                       = 65535
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  node_security_group_tags = merge(local.tags, var.enable_karpenter ? {
    "karpenter.sh/discovery" = local.name
  } : {})
  fargate_profiles = var.enable_karpenter ? {
    karpenter = {
      selectors = [
        { namespace = "karpenter" }
      ]
    }
  } : {}
  tags = merge(local.tags, var.enable_karpenter ? {
    "karpenter.sh/discovery" = local.name
  } : {})
  depends_on = [module.vpc]
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name}"
}