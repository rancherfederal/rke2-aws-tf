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
  name               = "${var.name}-rke2"
  assume_role_policy = data.aws_iam_policy_document.ec2_access.json
}

#
# Profile
#
resource "aws_iam_instance_profile" "this" {
  name = "${var.name}-rke2"
  role = aws_iam_role.this.name
}
