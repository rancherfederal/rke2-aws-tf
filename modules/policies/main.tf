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
# Role Policies
#
resource "aws_iam_role_policy" "this" {
  count = length(var.policies)

  name   = var.policies[count.index].name
  role   = aws_iam_role.this.id
  policy = var.policies[count.index].policy
}
