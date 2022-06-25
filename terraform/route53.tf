data "aws_route53_zone" "naked" {
  name = var.domain_name
}

resource "aws_route53_record" "main_acm_c" {
  for_each = {
    for d in aws_acm_certificate.main.domain_validation_options : d.domain_name => {
      name   = d.resource_record_name
      record = d.resource_record_value
      type   = d.resource_record_type
    }
  }
  zone_id         = data.aws_route53_zone.naked.id
  name            = each.value.name
  type            = each.value.type
  ttl             = 172800
  records         = [each.value.record]
  allow_overwrite = true
}

resource "aws_route53_record" "main_cdn_c" {
  zone_id = data.aws_route53_zone.naked.zone_id
  name    = local.fqdn.name
  type    = "A"
  alias {
    evaluate_target_health = true
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
  }
}