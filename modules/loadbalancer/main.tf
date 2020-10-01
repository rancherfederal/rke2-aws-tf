//resource "aws_security_group" "controlplane" {
//  name        = "${var.name}-cp"
//  description = "${var.name} controlplane"
//  vpc_id      = var.vpc_id
//
//  tags = merge({
//
//  }, var.tags)
//}
//
//resource "aws_security_group_rule" "cp_ingress" {
//  from_port         = var.cp_port
//  to_port           = var.cp_port
//  protocol          = "tcp"
//  security_group_id = aws_security_group.controlplane.id
//  type              = "ingress"
//  cidr_blocks       = var.cp_ingress_cidr_blocks
//}
//
//resource "aws_security_group_rule" "cp_supervisor_ingress" {
//  from_port         = var.cp_supervisor_port
//  to_port           = var.cp_supervisor_port
//  protocol          = "tcp"
//  security_group_id = aws_security_group.controlplane.id
//  type              = "ingress"
//  cidr_blocks       = var.cp_supervisor_ingress_cidr_blocks
//}
//
//resource "aws_elb" "controlplane" {
//  name    = "${var.name}-cp"
//  subnets = var.subnets
//
//  cross_zone_load_balancing = true
//  security_groups           = [aws_security_group.controlplane.id]
//
//  listener {
//    instance_port     = 6443
//    instance_protocol = "tcp"
//    lb_port           = 6443
//    lb_protocol       = "tcp"
//  }
//
//  listener {
//    instance_port     = 9345
//    instance_protocol = "tcp"
//    lb_port           = 9345
//    lb_protocol       = "tcp"
//  }
//
//  health_check {
//    healthy_threshold   = 2
//    interval            = 15
//    target              = "TCP:6443"
//    timeout             = 3
//    unhealthy_threshold = 2
//  }
//
//  tags = merge({
//
//  }, var.tags)
//}

resource "aws_lb" "controlplane" {
  name = "${var.name}-cp"

  internal                         = false
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = true

  subnets = var.subnets

  tags = merge({

  }, var.tags)
}

resource "aws_lb_target_group" "server" {
  name     = "${var.name}-server-tg"
  port     = var.cp_port
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    interval            = "10"
    port                = var.cp_port
    protocol            = "TCP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "server" {
  load_balancer_arn = aws_lb.controlplane.arn
  port              = var.cp_port
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.server.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "server_supervisor" {
  name     = "${var.name}-server-supervisor-tg"
  port     = var.cp_supervisor_port
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    interval            = "10"
    port                = var.cp_port
    protocol            = "TCP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "server_supervisor" {
  load_balancer_arn = aws_lb.controlplane.arn
  port              = var.cp_supervisor_port
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.server_supervisor.arn
    type             = "forward"
  }
}