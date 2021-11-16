locals {
  # Handle case where target group/load balancer name exceeds 32 character limit without creating illegal names
  controlplane_name = "${substr(var.name, 0, 23)}-rke2-cp"
  server_name       = "${substr(var.name, 0, 18)}-rke2-server"
  supervisor_name   = "${substr(var.name, 0, 15)}-rke2-supervisor"
}

resource "aws_security_group" "controlplane" {
  name        = local.controlplane_name
  description = "${local.controlplane_name} sg"
  vpc_id      = var.vpc_id

  tags = merge({}, var.tags)
}

resource "aws_security_group_rule" "apiserver" {
  from_port         = var.cp_port
  to_port           = var.cp_port
  protocol          = "tcp"
  security_group_id = aws_security_group.controlplane.id
  type              = "ingress"

  cidr_blocks = var.cp_ingress_cidr_blocks
}

resource "aws_security_group_rule" "supervisor" {
  from_port         = var.cp_supervisor_port
  to_port           = var.cp_supervisor_port
  protocol          = "tcp"
  security_group_id = aws_security_group.controlplane.id
  type              = "ingress"

  cidr_blocks = var.cp_supervisor_ingress_cidr_blocks
}

resource "aws_security_group_rule" "egress" {
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  security_group_id = aws_security_group.controlplane.id
  type              = "egress"

  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_elb" "controlplane" {
  name = local.controlplane_name

  internal        = var.internal
  subnets         = var.subnets
  security_groups = [aws_security_group.controlplane.id]

  cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  listener {
    instance_port     = var.cp_port
    instance_protocol = "TCP"
    lb_port           = var.cp_port
    lb_protocol       = "TCP"
  }

  listener {
    instance_port     = var.cp_supervisor_port
    instance_protocol = "TCP"
    lb_port           = var.cp_supervisor_port
    lb_protocol       = "TCP"
  }

  health_check {
    healthy_threshold   = 3
    interval            = 10
    target              = "TCP:${var.cp_port}"
    timeout             = 3
    unhealthy_threshold = 3
  }

  access_logs {
    # the bucket name isn't allowed to be empty in this block, so use its default value as the flag
    bucket  = var.access_logs_bucket
    enabled = var.access_logs_bucket != "disabled"
  }

  tags = merge({}, var.tags)
}
