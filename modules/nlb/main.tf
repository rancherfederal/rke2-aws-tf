locals {
  # Handle case where target group/load balancer name exceeds 32 character limit
  controlplane_name = substr("${var.name}-cp", 0, 31)
  server_name = substr("${var.name}-server", 0, 31)
  supervisor_name = substr("${var.name}-supervisor", 0, 31)

}

resource "aws_lb" "controlplane" {
  name = local.controlplane_name

  internal                         = var.internal
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  subnets                          = var.subnets

  tags = merge({
  }, var.tags)
}

resource "aws_lb_target_group" "server" {
  name     = local.server_name
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
  name     = local.supervisor_name
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