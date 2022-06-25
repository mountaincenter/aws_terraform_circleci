variable "aws_id" {}
variable "aws_access_key_id" {}
variable "aws_secret_access_key_id" {}
variable "aws_region" {}
variable "domain_name" {}
variable "domain_host_name" {}

provider "aws" {
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key_id
  region     = var.aws_region
}
provider "aws" {
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key_id
  region     = "us-east-1"
  alias      = "virginia"
}

locals {
  fqdn = {
    name = "${var.domain_host_name}.${var.domain_name}"
  }
  bucket = {
    name = local.fqdn.name
  }
}

resource "aws_s3_bucket" "cloudfront_logs" {
  bucket = "${local.fqdn.name}-cloudfront-logs"
  acl    = "private"
}

resource "aws_s3_bucket" "app" {
  bucket = local.bucket.name
  acl    = "private"
  policy = templatefile("bucket-policy.json", {
    "bucket_name" = local.bucket.name
  })

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

}

data "aws_cloudfront_cache_policy" "managed_caching_optimized" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "main" {
  origin {
    domain_name = "${local.bucket.name}.s3-${var.aws_region}.amazonaws.com"
    origin_id   = "S3-${local.fqdn.name}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # Alternate Domain Names (CNAMEs)
  aliases = [local.fqdn.name]

  # 証明書の設定
  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate.main.arn
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }

  retain_on_delete = false

  logging_config {
    include_cookies = true
    bucket          = "${aws_s3_bucket.cloudfront_logs.id}.s3.amazonaws.com"
    prefix          = "log/"
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${local.fqdn.name}"
    viewer_protocol_policy = "allow-all"
    compress               = true
    cache_policy_id        = data.aws_cloudfront_cache_policy.managed_caching_optimized.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}


resource "aws_cloudfront_origin_access_identity" "main" {
  comment = "Origin Access Identity for s3 ${local.bucket.name}"
}

resource "aws_acm_certificate" "main" {
  provider          = aws.virginia
  domain_name       = local.fqdn.name
  validation_method = "DNS"
}

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

resource "aws_acm_certificate_validation" "main" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.main_acm_c : record.fqdn]
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

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.app.arn}/*"]

    principals {
      identifiers = [aws_cloudfront_origin_access_identity.main.iam_arn]
      type        = "AWS"
    }
  }
}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.app.id
  policy = data.aws_iam_policy_document.s3_policy.json
}