resource "helm_release" "nginx" {
  name             = "nginx-ingress-controller"
  repository       = "oci://registry-1.docker.io/bitnamicharts"
  chart            = "nginx-ingress-controller"
  namespace        = "ingress-nginx"
  create_namespace = true
  values = [<<EOF
    service:
      type: ${var.nginx_controller_service_type}
    ingressClassResource:
      name: nginx
      enabled: true
    metrics:
      enabled: true
      serviceMonitor:
        enabled: true
        additionalLabels.release: "kube-prometheus-stack"
    podAnnotations:
      prometheus.io/port: "10254"
      prometheus.io/scrape: "true"

  EOF
  ]
  depends_on = [module.eks,
    helm_release.aws_lbc,
    helm_release.karpenter,
    module.karpenter,
    kubectl_manifest.karpenter_node_class,
    kubectl_manifest.karpenter_node_pool,
    helm_release.prometheus
  ]
}