resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "7.3.11"
  # values           = [file("${path.module}/values/argocd.yaml")]
  values = [<<EOF
    configs:
      params:
        server.insecure: true
  EOF
  ]
  depends_on = [module.eks,
    helm_release.karpenter,
    module.karpenter,
    kubectl_manifest.karpenter_node_class,
    kubectl_manifest.karpenter_node_pool
  ]
}
resource "kubernetes_ingress_v1" "arogcd" {
  metadata {
    name      = "argocd-ingress"
    namespace = "argocd"
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      host = "argocd.${var.domain_name}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "argocd-server"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
  depends_on = [helm_release.argocd,
    helm_release.aws_lbc,
    helm_release.nginx,
    module.eks,
    module.vpc,
    kubernetes_ingress_v1.alb_nginx,
  ]
}
