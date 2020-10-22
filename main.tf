locals {
  # Create a unique cluster name we'll prefix to all resources created and ensure it's lowercase
  uname = lower("${var.cluster_name}-${random_string.uid.result}")

  ccm_tags = {
    "kubernetes.io/cluster/${local.uname}" = "owned"
  }

  default_tags = {
    "ClusterName" = local.uname,
    "ClusterType" = "rke2",
  }

  cluster_data = {
    name       = local.uname
    server_url = module.cp_lb.dns
    cluster_sg = aws_security_group.cluster.id
    token      = module.statestore.token
  }
}

resource "random_string" "uid" {
  # NOTE: Don't get too crazy here, several aws resources have tight limits on lengths (such as load balancers), in practice we are also relying on users to uniquely identify their cluster names
  length  = 3
  special = false
  lower   = true
  upper   = false
  number  = false
}

#
# Cluster join token
#
resource "random_password" "token" {
  length  = 40
  special = false
}

module "statestore" {
  source = "./modules/statestore"
  name   = local.uname
  token  = random_password.token.result
  tags   = merge(local.default_tags, var.tags)
}

#
# Controlplane Load Balancer
#
module "cp_lb" {
  source  = "./modules/nlb"
  name    = local.uname
  vpc_id  = var.vpc_id
  subnets = var.subnets

  enable_cross_zone_load_balancing = var.controlplane_enable_cross_zone_load_balancing
  internal                         = var.controlplane_internal

  tags = merge({
  }, local.ccm_tags, local.default_tags, var.tags)
}

#
# Security Groups
#

# Shared Cluster Security Group
resource "aws_security_group" "cluster" {
  name        = "${local.uname}-rke2-cluster"
  description = "Shared ${local.uname} cluster security group"
  vpc_id      = var.vpc_id

  tags = merge({
    "shared" = "true",
  }, local.default_tags, var.tags)
}

resource "aws_security_group_rule" "cluster_shared" {
  description       = "Allow all inbound traffic between ${local.uname} cluster nodes"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.cluster.id
  type              = "ingress"

  self = true
}

resource "aws_security_group_rule" "cluster_egress" {
  description       = "Allow all outbound traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.cluster.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Server Security Group
resource "aws_security_group" "server" {
  name        = "${local.uname}-rke2-server"
  vpc_id      = var.vpc_id
  description = "${local.uname} rke2 server node pool"
  tags        = merge(local.default_tags, var.tags)
}

resource "aws_security_group_rule" "server_cp" {
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  security_group_id = aws_security_group.server.id
  type              = "ingress"
  cidr_blocks       = var.controlplane_allowed_cidrs
}

resource "aws_security_group_rule" "server_cp_supervisor" {
  from_port         = 9345
  to_port           = 9345
  protocol          = "tcp"
  security_group_id = aws_security_group.server.id
  type              = "ingress"
  cidr_blocks       = var.controlplane_allowed_cidrs
}

#
# IAM Role
#
module "iam" {
  count = var.iam_instance_profile == "" ? 1 : 0

  source = "./modules/policies"

  name = "${local.uname}-server"
  policies = [
    {
      name   = "${local.uname}-aws-ccm",
      policy = data.aws_iam_policy_document.aws_ccm[0].json,
    },
    {
      name   = "${local.uname}-get-token",
      policy = module.statestore.token.policy_document,
    },
    {
      name   = "${local.uname}-put-kubeconfig",
      policy = module.statestore.kubeconfig_put_policy,
    }
  ]
}

#
# Server Nodepool
#
module "servers" {
  source = "./modules/nodepool"
  name   = "server"

  vpc_id                 = var.vpc_id
  subnets                = var.subnets
  ami                    = var.ami
  ssh_authorized_keys    = var.ssh_authorized_keys
  block_device_mappings  = var.block_device_mappings
  vpc_security_group_ids = [aws_security_group.server.id]
  target_group_arns = [
    module.cp_lb.server_tg_arn,
    module.cp_lb.server_supervisor_tg_arn,
  ]

  # Overrideable variables
  userdata             = data.template_cloudinit_config.this.rendered
  iam_instance_profile = var.iam_instance_profile == "" ? module.iam[0].iam_instance_profile : var.iam_instance_profile

  # Don't allow the user to do something not recommended within etcd scaling, set max deliberately and only let them control desired
  asg = { min : 1, max : 7, desired : var.servers }

  # TODO: Ideally set this to `var.servers`, but currently blocked by: https://github.com/rancher/rke2/issues/349
  //  min_elb_capacity = 1

  # RKE2 Variables
  cluster_data = local.cluster_data
  rke2_version = var.rke2_version
  rke2_config  = var.rke2_config

  tags = merge({}, local.default_tags, var.tags)
}

