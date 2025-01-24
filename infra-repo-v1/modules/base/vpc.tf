module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.enable_nat_gateway && !var.single_nat_gateway

  public_subnet_tags = {
    "kubernetes.io/role/elb"              = "1"
    "kubernetes.io/cluster/${local.name}" = "shared"
  }

  private_subnet_tags = merge(
    {
      "kubernetes.io/role/internal-elb"     = "1"
      "kubernetes.io/cluster/${local.name}" = "shared"
    },
    var.enable_karpenter ? { "karpenter.sh/discovery" = local.name } : {}
    # Tags subnets for Karpenter auto-discovery
  )

  tags = local.tags
}
