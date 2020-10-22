locals {
  name = "${var.cluster_data.name}-${var.name}"
}

#
# IAM Role & Policies
#
module "iam" {
  count = var.iam_instance_profile == "" ? 1 : 0

  source = "../policies"
  name   = "${local.name}-agent"
}

resource "aws_iam_role_policy" "aws_ccm" {
  count = var.iam_instance_profile == "" && var.enable_ccm ? 1 : 0

  role   = module.iam[count.index].role
  policy = data.aws_iam_policy_document.aws_ccm[count.index].json
}

resource "aws_iam_role_policy" "aws_autoscaler" {
  count = var.iam_instance_profile == "" && var.enable_autoscaler ? 1 : 0

  role   = module.iam[count.index].role
  policy = data.aws_iam_policy_document.aws_autoscaler[count.index].json
}

resource "aws_iam_role_policy" "get_token" {
  count = var.iam_instance_profile == "" ? 1 : 0

  role   = module.iam[count.index].role
  policy = var.cluster_data.token.policy_document
}

#
# RKE2 Userdata
#
module "init" {
  source = "../userdata"

  server_url   = var.cluster_data.server_url
  token_bucket = var.cluster_data.token.bucket
  token_object = var.cluster_data.token.object
  agent        = true
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

  part {
    filename     = "00_download.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/../common/download.sh", {
      # Must not use `version` here since that is reserved
      rke2_version = var.rke2_version
      type         = "agent"
    })
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
  name   = local.name

  vpc_id                 = var.vpc_id
  subnets                = var.subnets
  ami                    = var.ami
  block_device_mappings  = var.block_device_mappings
  vpc_security_group_ids = [var.cluster_data.cluster_sg]
  userdata               = data.template_cloudinit_config.init.rendered
  iam_instance_profile   = var.iam_instance_profile == "" ? module.iam[0].iam_instance_profile : var.iam_instance_profile
  asg                    = var.asg

  tags = merge({
    "Name"                                           = "${local.name}-rke2-agent-nodepool",
    "kubernetes.io/cluster/${var.cluster_data.name}" = "owned",
    "Role"                                           = "agent",
  }, var.tags)
}