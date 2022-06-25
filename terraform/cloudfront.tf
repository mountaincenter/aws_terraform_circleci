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
    viewer_protocol_policy = "redirect-to-https"
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
