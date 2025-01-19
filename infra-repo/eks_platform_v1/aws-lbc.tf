# # New Fargate Profile for kube-system
# resource "aws_eks_fargate_profile" "kube_system" {
#   cluster_name           = module.eks.cluster_name
#   fargate_profile_name   = "kube-system"
#   pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
#   subnet_ids             = module.vpc.private_subnets

#   selector {
#     namespace = "kube-system"
#     labels = {
#       "app.kubernetes.io/name" = "aws-load-balancer-controller"
#       "fargate-schedulable"    = "yes"
#     }
#   }
#   depends_on = [module.eks]
# }

# Fargate Pod Execution Role
# resource "aws_iam_role" "fargate_pod_execution_role" {
#   name = "eks-fargate-pod-execution-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "eks-fargate-pods.amazonaws.com"
#         }
#       }
#     ]
#   })

# }

# Attach AWS managed policy for Fargate pod execution
# resource "aws_iam_role_policy_attachment" "fargate_pod_execution" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
#   role       = aws_iam_role.fargate_pod_execution_role.name
#   depends_on = [aws_iam_role.fargate_pod_execution_role]
# }

# AWS LBC IAM Policy
data "aws_iam_policy_document" "aws_lbc" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeTags",
      "ec2:GetCoipPoolUsage",
      "ec2:DescribeCoipPools",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags"
    ]
    resources = ["*"]
  }
  depends_on = [helm_release.karpenter]
}

data "aws_iam_policy_document" "aws_lbc_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
  depends_on = [helm_release.karpenter]
}

resource "aws_iam_role" "aws_lbc" {
  name               = "AWSLoadBalancerControllerRole"
  assume_role_policy = data.aws_iam_policy_document.aws_lbc_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "aws_lbc" {
  name   = "aws-load-balancer-controller"
  role   = aws_iam_role.aws_lbc.id
  policy = data.aws_iam_policy_document.aws_lbc.json
  # depends_on = [aws_iam_role.fargate_pod_execution_role]
}

resource "aws_eks_pod_identity_association" "aws_lbc" {
  cluster_name    = module.eks.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.aws_lbc.arn
  lifecycle {
    create_before_destroy = true
  }
}
