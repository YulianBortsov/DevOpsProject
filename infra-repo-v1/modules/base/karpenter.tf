locals {
  namespace = "karpenter"
}

################################################################################
# Controller & Node IAM roles, SQS Queue, Eventbridge Rules
################################################################################

module "karpenter" {
  source                = "terraform-aws-modules/eks/aws//modules/karpenter"
  version               = "~> 20.24"
  count                 = var.enable_karpenter ? 1 : 0
  cluster_name          = module.eks.cluster_name
  enable_v1_permissions = true
  namespace             = local.namespace

  # Name needs to match role name passed to the EC2NodeClass
  node_iam_role_use_name_prefix = false
  node_iam_role_name            = local.name

  # EKS Fargate does not support pod identity
  create_pod_identity_association = false
  enable_irsa                     = true
  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn

  tags = local.tags
  depends_on = [
    module.eks,
  ]
}
# resource "aws_iam_service_linked_role" "spot" {
#   aws_service_name = "spot.amazonaws.com"
#   description      = "Service linked role for AWS EC2 Spot Instances"
# }
############################################################################
# You need to make sure the AWS account has the service linked role for spot instance present
# If not, create it manually

################################################################################
# Helm charts
################################################################################

resource "helm_release" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  name                = "karpenter"
  namespace           = local.namespace
  create_namespace    = true
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "1.0.2"
  wait                = true
  wait_for_jobs       = true

  values = [
    <<-EOT
    dnsPolicy: Default
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter[0].queue_name}
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.karpenter[0].iam_role_arn}
    webhook:
      enabled: false
    controller:
      drain:
        timeout: 300s
    EOT
  ]

  lifecycle {
    ignore_changes = [
      repository_password
    ]
  }

  depends_on = [module.karpenter]
}

# resource "kubectl_manifest" "karpenter_node_class" {
#   count     = var.enable_karpenter ? 1 : 0
#   yaml_body = <<-YAML
#     apiVersion: karpenter.k8s.aws/v1
#     kind: EC2NodeClass
#     metadata:
#       name: default
#     spec:
#       amiSelectorTerms:
#         - alias: bottlerocket@latest
#       role: ${local.name}
#       subnetSelectorTerms:
#         - tags:
#             karpenter.sh/discovery: ${local.name}
#       securityGroupSelectorTerms:
#         - tags:
#             karpenter.sh/discovery: ${local.name}
#       tags:
#         karpenter.sh/discovery: ${local.name}
#   YAML

#   depends_on = [helm_release.karpenter]
# }

# resource "kubectl_manifest" "karpenter_node_pool" {
#   count = var.enable_karpenter ? 1 : 0

#   yaml_body = <<-YAML
#     apiVersion: karpenter.sh/v1
#     kind: NodePool
#     metadata:
#       name: default
#     spec:
#       template:
#         spec:
#           nodeClassRef:
#             group: karpenter.k8s.aws
#             kind: EC2NodeClass
#             name: default
#           requirements:
#             - key: "karpenter.k8s.aws/instance-category"
#               operator: In
#               values: ["c", "m", "t"]
#             - key: "karpenter.k8s.aws/instance-cpu"
#               operator: In
#               values: ["2" ,"4", "8", "16"]
#             - key: "karpenter.k8s.aws/instance-hypervisor"
#               operator: In
#               values: ["nitro"]
#             - key: "karpenter.k8s.aws/instance-generation"
#               operator: Gt
#               values: ["2"]
#             - key: "kubernetes.io/arch"
#               operator: In
#               values: ["amd64"]
#             - key: "karpenter.k8s.aws/instance-size"  # Add this to explicitly exclude nano
#               operator: NotIn
#               values: ["nano", "micro", "small", "medium"]    
#       limits:
#         cpu: 500
#       disruption:
#         consolidationPolicy: WhenEmpty
#         consolidateAfter: 15s
#   YAML
#   depends_on = [
#     kubectl_manifest.karpenter_node_class
#   ]
# }

# resource "kubectl_manifest" "aws_lbc_nodepool" {
#   count = var.enable_karpenter ? 1 : 0

#   yaml_body  = <<-YAML
# apiVersion: karpenter.sh/v1
# kind: NodePool
# metadata:
#   name: critical-workloads
# spec:
#   template:
#     spec:
#       nodeClassRef:
#             group: karpenter.k8s.aws
#             kind: EC2NodeClass
#             name: default
#       requirements:
#         - key: "karpenter.sh/capacity-type"
#           operator: In
#           values: ["on-demand"]
#         - key: "karpenter.k8s.aws/instance-category"
#           operator: In
#           values: ["t"]
#         - key: "karpenter.k8s.aws/instance-size"
#           operator: NotIn
#           values: ["nano", "micro", "small"]
#         - key: "karpenter.k8s.aws/instance-cpu"
#           operator: In
#           values: ["2","4"]
#         - key: "kubernetes.io/arch"
#           operator: In
#           values: ["amd64"]
#     metadata:
#       labels:
#         workload-type: "critical"
#     taints:
#       - key: aws-lbc
#         effect: NoSchedule
#   limits:
#     cpu: 200
#   disruption:
#     consolidationPolicy: WhenEmpty
#     consolidateAfter: 15s
# YAML
#   depends_on = [kubectl_manifest.karpenter_node_class]
# }

resource "null_resource" "karpenter_cleanup" {
  count = var.enable_karpenter ? 1 : 0

  depends_on = [
    module.karpenter,
    helm_release.karpenter,
    # kubectl_manifest.aws_lbc_nodepool,
    # kubectl_manifest.karpenter_node_class,
    # kubectl_manifest.karpenter_node_pool,
  ]

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      kubectl get deployments --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name' --no-headers | grep -v 'karpenter' | while read namespace name; do
        kubectl scale deployment "$name" --replicas=0 -n "$namespace"
      done
      sleep 90
    EOT

  }
}

resource "helm_release" "karpenter_manifests" {
  for_each = var.karpenter_config
  name               = each.key
  chart = "${path.module}/karpenter-manifests"
  wait = true
  force_update = true
  cleanup_on_fail = true
  set {
    name = "nodepool.tainted"
    value = each.value.tainted != null ? each.value.tainted : false
  }
  set {
    name = "nodepool.labeled"
    value = each.value.labeled != null ? each.value.labeled : false
  }
  set {
    name = "nodepool.enable_disruption"
    value = each.value.disruption != null ? each.value.disruption : false
  }
  set {
    name = "nodepool.cpu"
    value = each.value.limits.cpu
  }
  set {
    name = "nodepool.memory"
    value = each.value.limits.memory
  }

  values = [<<EOT
  ecn2:
    amiAlias: ${each.value.amiAlias}
    roleName: ${local.name}
    karpenterValue: ${local.name}
  
  nodepool:
    labels:
      key: ${each.value.labels.key}
      value: ${each.value.labels.value}
    taints:
      key: ${each.value.taints.key}
    instance_category:
      operator: ${each.value.instance_category.operator}
      values: ${jsonencode(each.value.instance_category.values)}
    instance_size:
      operator: ${each.value.instance_size.operator}
      values: ${jsonencode(each.value.instance_size.values)}
    instance_cpu:
      operator: ${each.value.instance_cpu.operator}
      values: ${jsonencode(each.value.instance_cpu.values)}
    instance_hypervisor:
      operator: ${each.value.instance_hypervisor.operator}
      values: ${jsonencode(each.value.instance_hypervisor.values)}
    instance_generation:
      operator: ${each.value.instance_generation.operator}
      values: ${jsonencode(each.value.instance_generation.values)}
    capacity_type:
      operator: ${each.value.capacity_type.operator}
      values: ${jsonencode(each.value.capacity_type.values)}
  EOT
  ]

  depends_on = [ 
    module.karpenter,
    helm_release.karpenter,
  ]
}