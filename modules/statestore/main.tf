
resource "aws_s3_bucket" "bucket" {
  count = var.existing_statebucket == null ? 1 : 0
  bucket        = lower("${var.name}-rke2")
  acl           = "private"
  force_destroy = true
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
  tags = merge({}, var.tags)
}


resource "aws_s3_bucket_object" "token" {
  bucket = var.existing_statebucket == null ? aws_s3_bucket.bucket[0].id : var.existing_statebucket
  key                    = "token"
  content_type           = "text/plain"
  content                = var.token
  server_side_encryption = "aws:kms"
}

data "aws_iam_policy_document" "getter" {
  dynamic "statement" {
    for_each = var.existing_statebucket == null ? [1] : []
    content {
      effect  = "Allow"
      actions = ["s3:GetObject"]
      resources = [
        "${aws_s3_bucket.bucket[0].arn}/${aws_s3_bucket_object.token.id}",
      ]
    }
  }
  dynamic "statement" {
    for_each = var.existing_statebucket == null ? [] : [1]
    content {
      effect  = "Allow"
      actions = ["s3:GetObject"]
      resources = [
        "arn:${var.aws_partition}:s3:::${var.existing_statebucket}/${aws_s3_bucket_object.token.id}",
      ]
    }
  }
}

data "aws_iam_policy_document" "setter" {
  dynamic "statement" {
    for_each = var.existing_statebucket == null ? [1] : []
    content {
      effect  = "Allow"
      actions = ["s3:PutObject"]
      resources = [
        "${aws_s3_bucket.bucket[0].arn}/rke2.yaml",
        

      ]
    }
  }
  dynamic "statement" {
    for_each = var.existing_statebucket == null ? [] : [1]
    content {
      effect  = "Allow"
      actions = ["s3:PutObject"]
      resources = [
        "arn:${var.aws_partition}:s3:::${var.existing_statebucket}/rke2.yaml",
      ]
    }
  }
}
