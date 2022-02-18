# only need a count of 2 when var.servers > 1
# the first instance will be for the leader and the 2nd will be for the server(s)
module "init" {
  count  = var.servers > 1 ? 2 : 1
  source = "./modules/userdata"

  server_url    = var.fqdn
  token_bucket  = module.statestore.bucket
  token_object  = module.statestore.token_object
  config        = var.rke2_config
  pre_userdata  = var.pre_userdata
  post_userdata = var.post_userdata
  ccm           = var.enable_ccm
  agent         = false
  is_leader     = count.index == 0 ? true : false
}

data "template_cloudinit_config" "this" {
  count         = var.servers > 1 ? 2 : 1
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
        set_rke2_version = length(var.rke2_version) > 0 ? true : false
        rke2_channel     = var.rke2_channel
        rke2_version     = var.rke2_version
        type             = "server"
      })
    }
  }

  # Use the appropriate index of module.init (0 = leader, 1 = servers)
  part {
    filename     = "01_rke2.sh"
    content_type = "text/x-shellscript"
    content      = module.init[count.index].templated
  }
}

data "aws_s3_object" "kube_config" {
  bucket = module.statestore.bucket
  key    = "rke2.yaml"

  depends_on = [
    module.leader
  ]
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
