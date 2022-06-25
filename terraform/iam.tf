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
