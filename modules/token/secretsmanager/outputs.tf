output "token" {
  value = {
    address         = aws_secretsmanager_secret.cluster.name
    policy_document = data.aws_iam_policy_document.getter.json
  }
}