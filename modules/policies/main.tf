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
  name = var.name

  assume_role_policy   = data.aws_iam_policy_document.ec2_access.json
  permissions_boundary = var.permissions_boundary

  tags = var.tags
}

#
# Profile
#
resource "aws_iam_instance_profile" "this" {
  name = var.name
  role = aws_iam_role.this.name
}
