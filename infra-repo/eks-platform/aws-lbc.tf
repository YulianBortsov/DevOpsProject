data "aws_iam_policy_document" "aws_lbc" {
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

}
resource "aws_iam_role" "aws_lbc" {
  name               = "${var.cluster_name}-lb-controller"
  assume_role_policy = data.aws_iam_policy_document.aws_lbc.json
  tags               = local.tags
}
resource "aws_iam_policy" "aws_lbc" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("${path.module}/iam-aws-lbc/iam_policy.json")
  tags   = local.tags

}
resource "aws_iam_role_policy_attachment" "aws_lbc" {
  role       = aws_iam_role.aws_lbc.name
  policy_arn = aws_iam_policy.aws_lbc.arn

}
resource "aws_eks_pod_identity_association" "aws_lbc" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.aws_lbc.arn
  lifecycle {
    create_before_destroy = true # This is required to avoid conflicts
  }
  depends_on = [module.eks]
}

resource "helm_release" "aws_lbc" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.11.0"
  set {
    name  = "clusterName"
    value = var.cluster_name
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  set {
    name  = "replicaCount"
    value = "1"
  }
  values = [
    <<-EOT
    tolerations:
      - key: "CriticalAddonsOnly"
        operator: "Equal"
        value: "true"
        effect: "NoSchedule"

    EOT
  ]
  depends_on = [
    module.eks,
    aws_eks_pod_identity_association.aws_lbc,
    aws_iam_policy.aws_lbc,
    aws_iam_role_policy_attachment.aws_lbc,
    aws_iam_role.aws_lbc,
    data.aws_iam_policy_document.aws_lbc,
    helm_release.karpenter,
    module.karpenter,
    kubectl_manifest.karpenter_node_class,
    kubectl_manifest.karpenter_node_pool
  ]
}


