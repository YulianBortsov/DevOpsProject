module "eks_blueprints_addons_lbc" {
  source = "aws-ia/eks-blueprints-addons/aws"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Critical addons
  eks_addons = {
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
    }
  }
  enable_aws_load_balancer_controller = true
  # AWS Load Balancer Controller configuration
  aws_load_balancer_controller = {
    wait          = true
    wait_for_jobs = true
    timeout       = 300
    values = [<<-EOF
      podIdentity:
        enabled: true
      serviceAccount:
        create: true
      region: ${var.region}
      vpcId: ${module.vpc.vpc_id}
      image:
        repository: 602401143452.dkr.ecr.${var.region}.amazonaws.com/amazon/aws-load-balancer-controller
      nodeSelector:
        workload-type: critical
      tolerations:
        - key: "workload-type"
          values: "critical"
          effect: "NoSchedule"
    EOF
    ]
  }

  depends_on = [
    aws_iam_role_policy.aws_lbc,
    aws_eks_pod_identity_association.aws_lbc,
    kubectl_manifest.karpenter_node_pool,
    kubectl_manifest.aws_lbc_nodepool,
    aws_iam_role.ebs_csi_driver,
    aws_iam_role_policy_attachment.ebs_csi_driver,
    aws_eks_pod_identity_association.ebs_csi_driver,
    data.aws_iam_policy_document.ebs_csi_driver
  ]
}

module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_argocd                = true # Sort the aws lbc webhook problem when provisioning
  enable_external_secrets      = true # Sort the aws lbc webhook problem when provisioning
  enable_kube_prometheus_stack = true

  kube_prometheus_stack = {
    name       = "kube-prometheus-stack"
    namespace  = "monitoring"
    repository = "https://prometheus-community.github.io/helm-charts"
    values = [<<-EOF
      prometheus:
        prometheusSpec:
          podMonitorSelectorNilUsesHelmValues: false
          serviceMonitorSelectorNilUsesHelmValues: false
          serviceMonitorSelector:
            matchLabels:
              release: kube-prometheus-stack 
      prometheus-node-exporter:
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                  - key: eks.amazonaws.com/compute-type
                    operator: NotIn
                    values:
                      - fargate
    EOF
    ]
  }

  argocd = {
    name          = "argocd"
    chart_version = "7.3.11"
    repository    = "https://argoproj.github.io/argo-helm"
    namespace     = "argocd"
    values = [<<-EOF
        configs:
            params:
                server.insecure: true
    EOF
    ]
  }

  depends_on = [
    aws_iam_role_policy.aws_lbc,
    aws_eks_pod_identity_association.aws_lbc,
    kubectl_manifest.karpenter_node_pool,
    kubectl_manifest.aws_lbc_nodepool,
    aws_iam_role.ebs_csi_driver,
    aws_eks_pod_identity_association.ebs_csi_driver,
    module.eks_blueprints_addons_lbc
  ]
}