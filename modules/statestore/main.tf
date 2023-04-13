resource "aws_s3_bucket" "bucket" {
  bucket        = lower("${var.name}-rke2")
  force_destroy = true

  tags = merge({}, var.tags)
}

resource "aws_s3_bucket_acl" "acl" {
  depends_on = [aws_s3_bucket_ownership_controls.bucket_owner_control]
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_ownership_controls" "bucket_owner_control" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
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

data "aws_iam_policy_document" "deny_insecure_transport" {
  count = var.attach_deny_insecure_transport_policy ? 1 : 0

  statement {
    sid    = "denyInsecureTransport"
    effect = "Deny"

    actions = [
      "s3:*",
    ]

    resources = [
      aws_s3_bucket.bucket.arn,
      "${aws_s3_bucket.bucket.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  count = var.attach_deny_insecure_transport_policy ? 1 : 0

  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.deny_insecure_transport[0].json
}
