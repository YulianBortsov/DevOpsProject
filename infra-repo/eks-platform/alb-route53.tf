data "aws_lb" "alb_nginx" {
  name       = "${local.name}-alb"
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
    name                   = data.aws_lb.alb_nginx.dns_name
    zone_id                = data.aws_lb.alb_nginx.zone_id
    evaluate_target_health = true
  }
  depends_on = [data.aws_lb.alb_nginx, data.aws_route53_zone.zone]
}