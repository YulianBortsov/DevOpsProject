module "acm" {
  source                    = "terraform-aws-modules/acm/aws"
  version                   = "~> 4.0"
  domain_name               = var.domain_name
  zone_id                   = data.aws_route53_zone.zone.zone_id
  validation_method         = "DNS"
  subject_alternative_names = ["*.${var.domain_name}"]
  wait_for_validation       = true
  tags                      = local.tags
}

data "aws_acm_certificate" "cert" {
  domain     = var.domain_name
  statuses   = ["ISSUED"]
  depends_on = [module.acm]
}