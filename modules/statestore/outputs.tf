output "bucket" {
  value = aws_s3_bucket_object.token.bucket
}

output "token_object" {
  value = aws_s3_bucket_object.token.id
}

output "kubeconfig_put_policy" {
  value = data.aws_iam_policy_document.setter.json
}

output "token" {
  value = {
    bucket = var.existing_statebucket == null ? aws_s3_bucket.bucket[0].id : var.existing_statebucket
    object          = aws_s3_bucket_object.token.id
    policy_document = data.aws_iam_policy_document.getter.json
    bucket_arn = var.existing_statebucket == null ? "${aws_s3_bucket.bucket[0].arn}/rke2.yaml" : "arn:${var.aws_partition}:s3:::${var.existing_statebucket}/${aws_s3_bucket_object.token.id}"
  }
}





