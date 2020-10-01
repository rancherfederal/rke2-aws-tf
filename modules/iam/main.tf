data "aws_iam_policy_document" "server" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "server" {
  name               = "${var.name}-server"
  assume_role_policy = data.aws_iam_policy_document.server.json
}

resource "aws_iam_instance_profile" "server" {
  name = "${var.name}-server"
  role = aws_iam_role.server.name
}

resource "aws_iam_role_policy_attachment" "server" {
  role = aws_iam_role.server.name
  //  policy_arn = aws_iam_poli
}

resource "aws_iam_policy" "server" {
  policy = <<-EOT

EOT
}