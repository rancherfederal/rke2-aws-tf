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

resource "aws_security_group_rule" "server_cp" {
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "server_cp_supervisor" {
  from_port         = 9345
  to_port           = 9345
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

module "nodepool" {
  source = "../nodepool"

  name    = "${var.name}-server"
  vpc_id  = var.vpc_id
  subnets = var.subnets

  instance_type = var.instance_type
  ami           = var.ami

  userdata               = data.template_cloudinit_config.this.rendered
  vpc_security_group_ids = concat([aws_security_group.this.id], [var.cluster_data.cluster_security_group], var.extra_security_groups)
  target_group_arns = [
    var.server_tg_arn,
    var.server_supervisor_tg_arn,
  ]

  tags = local.tags
}
