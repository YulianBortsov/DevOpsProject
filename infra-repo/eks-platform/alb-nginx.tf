resource "kubernetes_ingress_v1" "alb_nginx" {
  wait_for_load_balancer = true
  metadata {
    name      = "alb-nginx"
    namespace = "ingress-nginx"
    annotations = {
      "alb.ingress.kubernetes.io/scheme"             = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"        = "ip"
      "alb.ingress.kubernetes.io/healthcheck-path"   = "/healthz"
      "alb.ingress.kubernetes.io/certificate-arn"    = "${data.aws_acm_certificate.cert.arn}"
      "alb.ingress.kubernetes.io/listen-ports"       = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"       = "443"
      "alb.ingress.kubernetes.io/load-balancer-name" = "${local.name}-alb"
    }
  }
  spec {
    ingress_class_name = "alb"
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "nginx-ingress-controller"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
  depends_on = [helm_release.aws_lbc,
    helm_release.nginx,
    module.eks,
    module.vpc,
    aws_eks_pod_identity_association.aws_lbc,
    module.acm,
  ]
}