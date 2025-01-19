module "acm" {
  source                    = "terraform-aws-modules/acm/aws"
  version                   = "~> 4.0"
  domain_name               = var.domain_name
  zone_id                   = data.aws_route53_zone.zone.zone_id
  validation_method         = "DNS"
  subject_alternative_names = ["*.${var.domain_name}"]
  wait_for_validation       = true
}

data "aws_acm_certificate" "cert" {
  domain     = var.domain_name
  statuses   = ["ISSUED"]
  depends_on = [module.acm]
}

data "aws_alb" "alb_nginx" {
  name       = var.alb_name
  depends_on = [kubernetes_ingress_v1.alb_nginx]
}

data "aws_route53_zone" "zone" {
  name = var.domain_name
}

resource "aws_route53_record" "alb_nginx" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "*.${var.domain_name}"
  type    = "A"
  alias {
    name                   = data.aws_alb.alb_nginx.dns_name
    zone_id                = data.aws_alb.alb_nginx.zone_id
    evaluate_target_health = true
  }
  depends_on = [data.aws_alb.alb_nginx, data.aws_route53_zone.zone]
}