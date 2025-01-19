resource "helm_release" "prometheus" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  values = [<<EOF
    prometheus:
        prometheusSpec:
            podMonitorSelectorNilUsesHelmValues: false
            serviceMonitorSelectorNilUsesHelmValues: false
  EOF
  ]
  depends_on = [helm_release.karpenter,
    module.karpenter,
    kubectl_manifest.karpenter_node_class,
    kubectl_manifest.karpenter_node_pool
  ]
}