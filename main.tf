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

  token_store = var.token_store == "secretsmanager" ? module.secretsmanager_token_store[0] : module.s3_token_store[0]

  # Map of generated objects required for cluster joining, not intended for user interaction
  cluster_data = {
    name       = local.uname
    server_dns = module.cp_lb.dns
    cluster_sg = aws_security_group.cluster.id
    token      = var.token_store == "secretsmanager" ? module.secretsmanager_token_store[0].token : module.s3_token_store[0].token
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

module "s3_token_store" {
  count  = var.token_store == "s3" ? 1 : 0
  source = "./modules/token/s3"
  name   = local.uname
  token  = random_password.token.result
  tags   = merge(local.default_tags, var.tags)
}

module "secretsmanager_token_store" {
  count  = var.token_store == "secretsmanager" ? 1 : 0
  source = "./modules/token/secretsmanager"
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
  tags = merge({
  }, local.ccm_tags, local.default_tags, var.tags)
}

#
# Server Nodepool
#
module "servers" {
  source               = "./modules/server-nodepool"
  name                 = "${local.uname}-server"
  vpc_id               = var.vpc_id
  subnets              = var.subnets
  ami                  = var.ami
  ssh_authorized_keys  = var.ssh_authorized_keys
  iam_instance_profile = var.iam_instance_profile
  asg                  = var.asg

  controlplane_allowed_cirds = var.controlplane_allowed_cidrs
  server_tg_arn              = module.cp_lb.server_tg_arn
  server_supervisor_tg_arn   = module.cp_lb.server_supervisor_tg_arn

  cluster_data  = local.cluster_data
  rke2_config   = var.rke2_config
  pre_userdata  = var.pre_userdata
  post_userdata = var.post_userdata

  tags = merge({
  }, local.default_tags, var.tags)
}

#
# Shared Cluster Security Group
#
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
