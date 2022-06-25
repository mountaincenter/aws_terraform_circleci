resource "aws_acm_certificate" "main" {
  provider          = aws.virginia
  domain_name       = local.fqdn.name
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "main" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.main_acm_c : record.fqdn]
}