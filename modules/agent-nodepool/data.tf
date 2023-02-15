# Required IAM Policy for AWS CCM
data "aws_iam_policy_document" "aws_ccm" {
  count = var.iam_instance_profile == "" && var.enable_ccm ? 1 : 0

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeVolumes",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifyVolume",
      "ec2:AttachVolume",
      "ec2:DeleteVolume",
      "ec2:DetachVolume",
      "ec2:AuthorizeSecurityGroupIngress",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:BatchGetImage",
      "autoscaling:DescribeTags",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
    ]
  }
}

# Required IAM Policy for AWS Cluster Autoscaler
data "aws_iam_policy_document" "aws_autoscaler" {
  count = var.iam_instance_profile == "" && var.enable_autoscaler ? 1 : 0

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DescribeInstanceTypes"
    ]
  }
}
