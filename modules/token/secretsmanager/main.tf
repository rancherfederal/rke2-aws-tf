resource "random_string" "uid" {
  length  = 5
  special = false
}

resource "aws_secretsmanager_secret" "cluster" {
  name = "rke2-${var.name}-${random_string.uid.result}-token"

  tags = merge({}, var.tags)
}

resource "aws_secretsmanager_secret_version" "token" {
  secret_id     = aws_secretsmanager_secret.cluster.id
  secret_string = var.token
}

data "aws_iam_policy_document" "getter" {
  statement {
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      aws_secretsmanager_secret.cluster.arn
    ]
  }
}
