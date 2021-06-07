locals {
  name = "${var.cluster_data.name}-${var.name}"

  default_tags = {
    "ClusterType" = "rke2",
  }

  ccm_tags = {
    "kubernetes.io/cluster/${var.cluster_data.name}" = "owned",
  }

  autoscaler_tags = {
    "k8s.io/cluster-autoscaler/enabled"                  = var.enable_autoscaler,
    "k8s.io/cluster-autoscaler/${var.cluster_data.name}" = var.enable_autoscaler,
  }
}

#
# IAM Role & Policies
#
module "iam" {
  count = var.iam_instance_profile == "" ? 1 : 0

  source = "../policies"
  name   = "${local.name}-rke2-agent"

  permissions_boundary = var.iam_permissions_boundary

  tags = merge({}, local.default_tags, var.tags)
}

resource "aws_iam_role_policy" "aws_ccm" {
  count = var.iam_instance_profile == "" && var.enable_ccm ? 1 : 0

  name   = "${local.name}-rke2-agent-aws-ccm"
  role   = module.iam[count.index].role
  policy = data.aws_iam_policy_document.aws_ccm[count.index].json
}

resource "aws_iam_role_policy" "aws_autoscaler" {
  count = var.iam_instance_profile == "" && var.enable_autoscaler ? 1 : 0

  name   = "${local.name}-rke2-agent-aws-autoscaler"
  role   = module.iam[count.index].role
  policy = data.aws_iam_policy_document.aws_autoscaler[count.index].json
}

resource "aws_iam_role_policy" "get_token" {
  count = var.iam_instance_profile == "" ? 1 : 0

  name   = "${local.name}-rke2-agent-aws-get-token"
  role   = module.iam[count.index].role
  policy = var.cluster_data.token.policy_document
}

#
# RKE2 Userdata
#
module "init" {
  source = "../userdata"

  server_url    = var.cluster_data.server_url
  token_bucket  = var.cluster_data.token.bucket
  token_object  = var.cluster_data.token.object
  config        = var.rke2_config
  pre_userdata  = var.pre_userdata
  post_userdata = var.post_userdata
  ccm           = var.enable_ccm
  agent         = true
}

data "template_cloudinit_config" "init" {
  gzip          = true
  base64_encode = true

  # Main cloud-init config file
  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/../nodepool/files/cloud-config.yaml", {
      ssh_authorized_keys = var.ssh_authorized_keys
    })
  }

  dynamic "part" {
    for_each = var.download ? [1] : []
    content {
      filename     = "00_download.sh"
      content_type = "text/x-shellscript"
      content = templatefile("${path.module}/../common/download.sh", {
        # Must not use `version` here since that is reserved
        rke2_version = var.rke2_version
        type         = "agent"
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
# RKE2 Node Pool
#
module "nodepool" {
  source = "../nodepool"
  name   = "${local.name}-agent"

  vpc_id                      = var.vpc_id
  subnets                     = var.subnets
  ami                         = var.ami
  instance_type               = var.instance_type
  block_device_mappings       = var.block_device_mappings
  extra_block_device_mappings = var.extra_block_device_mappings
  vpc_security_group_ids      = concat([var.cluster_data.cluster_sg], var.extra_security_group_ids)
  userdata                    = data.template_cloudinit_config.init.rendered
  iam_instance_profile        = var.iam_instance_profile == "" ? module.iam[0].iam_instance_profile : var.iam_instance_profile
  asg                         = var.asg
  spot                        = var.spot
  wait_for_capacity_timeout   = var.wait_for_capacity_timeout

  tags = merge({
    "Role" = "agent",
  }, local.default_tags, local.ccm_tags, local.autoscaler_tags, var.tags)
}
