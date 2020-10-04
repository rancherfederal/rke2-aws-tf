output "bucket" {
  value = aws_s3_bucket_object.token.bucket
}

output "token_object" {
  value = aws_s3_bucket_object.token.id
}

output "token" {
  value = {
    address         = "s3://${aws_s3_bucket_object.token.bucket}/${aws_s3_bucket_object.token.id}"
    policy_document = data.aws_iam_policy_document.getter.json
  }
}