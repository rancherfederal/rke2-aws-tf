#
# Role
#
data "aws_iam_policy_document" "ec2_access" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.name}-rke2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_access.json
}

#
# Profile
#
resource "aws_iam_instance_profile" "this" {
  name = "${var.name}-rke2-profile"
  role = aws_iam_role.this.name
}

#
# Token Policy
#
resource "aws_iam_policy" "token" {
  name        = "${var.name}-rke2-get-token"
  path        = "/"
  description = "${var.name} rke2 token get"

  policy = var.token_policy
}

resource "aws_iam_policy_attachment" "token" {
  name       = "${var.name}-rke2-token-attachment"
  roles      = [aws_iam_role.this.name]
  policy_arn = aws_iam_policy.token.arn
}

#
# $NODE_TYPE Policy
#
resource "aws_iam_policy" "ccm" {
  name        = "${var.name}-rke2-aws-ccm"
  path        = "/"
  description = "${var.name} aws ccm policy"

  policy = var.ccm_policy
}

resource "aws_iam_policy_attachment" "ccm" {
  name       = "${var.name}-rke2-aws-ccm-attachment"
  roles      = [aws_iam_role.this.name]
  policy_arn = aws_iam_policy.ccm.arn
}
