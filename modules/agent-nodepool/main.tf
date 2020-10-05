locals {
  tags = merge({
    "Name"                                           = "${var.cluster_data.name}-${var.name}-nodepool",
    "kubernetes.io/cluster/${var.cluster_data.name}" = "owned"
  }, var.tags)
}


resource "aws_security_group" "this" {
  name        = "${var.name}-rke2-nodepool"
  vpc_id      = var.vpc_id
  description = "${var.name} node pool"
  tags        = local.tags
}

module "nodepool" {
  source = "../nodepool"

  name                   = "${var.name}-agent"
  vpc_id                 = var.vpc_id
  subnets                = var.subnets
  instance_type          = var.instance_type
  ami                    = var.ami
  spot                   = var.spot
  iam_instance_profile   = var.iam_instance_profile == "" ? module.iam[0].iam_instance_profile : var.iam_instance_profile
  userdata               = data.template_cloudinit_config.this.rendered
  vpc_security_group_ids = concat([aws_security_group.this.id], [var.cluster_data.cluster_sg], var.extra_security_groups)
  asg                    = var.asg
  block_device_mappings  = var.block_device_mappings

  tags = local.tags
}

#
# Required IAM Policy for AWS CCM
#
data "aws_iam_policy_document" "aws_ccm" {
  count = var.iam_instance_profile == "" ? 1 : 0
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:BatchGetImage"
    ]
  }
}

module "iam" {
  count = var.iam_instance_profile == "" ? 1 : 0

  source       = "../policies"
  name         = var.name
  token_policy = var.cluster_data.token.policy_document
  ccm_policy   = data.aws_iam_policy_document.aws_ccm[0].json
}
