resource "aws_s3_bucket" "cloudfront_logs" {
  bucket = "${local.fqdn.name}-cloudfront-logs"
  acl    = "private"
  force_destroy = true
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
  force_destroy = true
}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.app.id
  policy = data.aws_iam_policy_document.s3_policy.json
}