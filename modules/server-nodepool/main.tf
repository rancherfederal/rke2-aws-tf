locals {
  tags = merge({
    "Name"                                           = "${var.name}-rke2-nodepool",
    "kubernetes.io/cluster/${var.cluster_data.name}" = "owned"
    "Role"                                           = "Server",
  }, var.tags)
}

resource "aws_security_group" "this" {
  name        = "${var.name}-rke2-nodepool"
  vpc_id      = var.vpc_id
  description = "${var.name} node pool"
  tags        = local.tags
}

resource "aws_security_group_rule" "server_cp" {
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  type              = "ingress"
  cidr_blocks       = var.controlplane_allowed_cirds
}

resource "aws_security_group_rule" "server_cp_supervisor" {
  from_port         = 9345
  to_port           = 9345
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  type              = "ingress"
  cidr_blocks       = var.controlplane_allowed_cirds
}

module "nodepool" {
  source = "../nodepool"

  name                   = var.name
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
  target_group_arns = [
    var.server_tg_arn,
    var.server_supervisor_tg_arn,
  ]

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
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVolumes",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifyVolume",
      "ec2:AttachVolume",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteVolume",
      "ec2:DetachVolume",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DescribeVpcs",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:AttachLoadBalancerToSubnets",
      "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateLoadBalancerPolicy",
      "elasticloadbalancing:CreateLoadBalancerListeners",
      "elasticloadbalancing:ConfigureHealthCheck",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteLoadBalancerListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DetachLoadBalancerFromSubnets",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancerPolicies",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
      "iam:CreateServiceLinkedRole",
      "kms:DescribeKey"
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