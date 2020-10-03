locals {
  ccm_tags = {
    "kubernetes.io/cluster/${var.name}" = "owned"
  }
}

resource "random_password" "token" {
  length  = 32
  special = false
}

#
# Controlplane Load Balancer
#
module "cp_lb" {
  source  = "./modules/loadbalancer"
  name    = var.name
  vpc_id  = var.vpc_id
  subnets = var.subnets
  tags = merge({

  }, local.ccm_tags, var.tags)
}

#
# Server Nodepool
#
module "servers" {
  source              = "./modules/server-nodepool"
  name                = "server"
  vpc_id              = var.vpc_id
  subnets             = var.subnets
  ami                 = var.ami
  ssh_authorized_keys = var.ssh_authorized_keys

  cluster_data = {
    name                   = var.name
    server_dns             = module.cp_lb.dns
    cluster_security_group = aws_security_group.cluster.id
    token                  = random_password.token.result
  }

  server_tg_arn            = module.cp_lb.server_tg_arn
  server_supervisor_tg_arn = module.cp_lb.server_supervisor_tg_arn

  tags = merge({
    "Role" = "Server",
  }, var.tags)
}

#
# Shared Cluster Security Group
#
resource "aws_security_group" "cluster" {
  name        = "${var.name}-cluster"
  description = "Shared ${var.name} cluster security group"
  vpc_id      = var.vpc_id

  tags = merge({
    "shared" = "true",
  }, var.tags)
}

resource "aws_security_group_rule" "cluster_shared" {
  description       = "Allow all inbound traffic between cluster nodes"
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
