module "init" {
  source = "./modules/userdata"

  server_url    = module.cp_lb.dns
  token_bucket  = module.statestore.bucket
  token_object  = module.statestore.token_object
  config        = var.rke2_config
  pre_userdata  = var.pre_userdata
  post_userdata = var.post_userdata
  ccm           = var.enable_ccm
  agent         = false
}

data "template_cloudinit_config" "this" {
  gzip          = true
  base64_encode = true

  # Main cloud-init config file
  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/modules/nodepool/files/cloud-config.yaml", {
      ssh_authorized_keys = var.ssh_authorized_keys
    })
  }

  dynamic "part" {
    for_each = var.download ? [1] : []
    content {
      filename     = "00_download.sh"
      content_type = "text/x-shellscript"
      content = templatefile("${path.module}/modules/common/download.sh", {
        # Must not use `version` here since that is reserved
        rke2_version = var.rke2_version
        type         = "server"
      })
    }
  }

  part {
    filename     = "01_rke2.sh"
    content_type = "text/x-shellscript"
    content      = module.init.templated
  }
}

#
# IAM Policies
#
data "aws_iam_policy_document" "aws_required" {
  count = var.iam_instance_profile == "" ? 1 : 0

  # "Leader election" requires querying the instances autoscaling group/instances
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
    ]
  }
}

# Required IAM Policy for AWS CCM
data "aws_iam_policy_document" "aws_ccm" {
  count = var.iam_instance_profile == "" && var.enable_ccm ? 1 : 0

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:DescribeAutoScalingInstances",
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
