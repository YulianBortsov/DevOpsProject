resource "helm_release" "nginx" {
  name             = "nginx-ingress-controller"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  values = [<<EOF
    controller:
        service:
          type: ClusterIP
        ingressClassResource:
          name: nginx
          enabled: true
        metrics:
          enabled: true
          serviceMonitor:
            enabled: true
            additionalLabels:
              release: kube-prometheus-stack
        podAnnotations:
          prometheus.io/port: "10254"
          prometheus.io/scrape: "true"
        extraArgs:
          metrics-per-host: "false"

  EOF
  ]
  depends_on = [
    module.eks_blueprints_addons,
    null_resource.wait_for_aws_lb_controller
  ]
}

resource "null_resource" "wait_for_aws_lb_controller" {
  depends_on = [module.eks_blueprints_addons]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for AWS Load Balancer Controller pods..."
      kubectl wait --namespace kube-system \
        --for=condition=ready pod \
        --selector app.kubernetes.io/name=aws-load-balancer-controller \
        --timeout=300s
      
      # Additional wait to ensure everything is fully operational
      sleep 30
    EOT
  }
}
