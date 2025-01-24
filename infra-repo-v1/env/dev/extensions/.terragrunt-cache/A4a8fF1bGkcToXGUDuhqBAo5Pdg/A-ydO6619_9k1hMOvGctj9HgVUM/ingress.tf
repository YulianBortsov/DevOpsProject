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
      "alb.ingress.kubernetes.io/load-balancer-name" = local.alb_name
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
              name = "nginx-ingress-controller-ingress-nginx-controller"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
  depends_on = [
    helm_release.nginx,
    module.eks_blueprints_addons,
    null_resource.ingress_cleanup
  ]
}

resource "null_resource" "ingress_cleanup" {

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Waiting for ALB deletion..."
      sleep 60
    EOT
  }

  #   depends_on = [null_resource.karpenter_cleanup]
}

resource "kubernetes_ingress_v1" "arogcd" {
  metadata {
    name      = "argocd-ingress"
    namespace = "argocd"
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      host = "argocd.${var.environment}.${var.domain_name}"
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
  depends_on = [
    helm_release.nginx,
    # module.eks,
    # module.vpc,
    kubernetes_ingress_v1.alb_nginx,
    module.eks_blueprints_addons
  ]
}

resource "kubernetes_ingress_v1" "grafana" {
  metadata {
    name      = "grafana-ingress"
    namespace = "monitoring"
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      host = "grafana.${var.environment}.${var.domain_name}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "kube-prometheus-stack-grafana"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
  depends_on = [
    helm_release.nginx,
    # module.eks,
    # module.vpc,
    kubernetes_ingress_v1.alb_nginx,
    # module.loki_stack
  ]
}