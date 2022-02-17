resource "aws_s3_bucket" "bucket" {
  bucket        = lower("${var.name}-rke2")
  force_destroy = true

  tags = merge({}, var.tags)
}

resource "aws_s3_bucket_acl" "acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ssec" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_object" "token" {
  bucket                 = aws_s3_bucket.bucket.id
  key                    = "token"
  content_type           = "text/plain"
  content                = var.token
  server_side_encryption = "aws:kms"
}

data "aws_iam_policy_document" "getter" {
  statement {
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.bucket.arn}/${aws_s3_bucket_object.token.id}",
    ]
  }
}

data "aws_iam_policy_document" "setter" {
  statement {
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.bucket.arn}/rke2.yaml",
    ]
  }
}
