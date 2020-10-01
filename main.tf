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
  tags    = var.tags
}

#
# Server Nodes
#
resource "aws_instance" "servers" {
  count = var.server_count

  ami              = var.ami
  instance_type    = var.instance_type
  subnet_id        = var.subnets[0]
  user_data_base64 = data.template_cloudinit_config.this[count.index].rendered

  vpc_security_group_ids = [aws_security_group.cluster.id, aws_security_group.server.id]

  root_block_device {
    volume_size = var.block_device_mappings.size
    volume_type = "gp2"
    encrypted   = var.block_device_mappings.encrypted
  }

  tags = merge({
    "Name" = "${var.name}-server-${count.index}"
    "Role" = "server"
  }, var.tags)
}

//resource "aws_elb_attachment" "server_lb_attachments" {
//  count = length(aws_instance.servers)
//
//  elb = module.cp_lb.id
//  instance = aws_instance.servers[count.index].id
//}

resource "aws_lb_target_group_attachment" "server_tg_attachments" {
  count = length(aws_instance.servers)

  target_group_arn = module.cp_lb.server_tg_arn
  target_id        = aws_instance.servers[count.index].id
}

resource "aws_lb_target_group_attachment" "server_supervisor_tg_attachments" {
  count = length(aws_instance.servers)

  target_group_arn = module.cp_lb.server_supervisor_tg_arn
  target_id        = aws_instance.servers[count.index].id
}

#
# Shared Cluster Security Group
#
resource "aws_security_group" "cluster" {
  name        = "${var.name}-cluster"
  description = "Shared ${var.name} cluster security group"
  vpc_id      = var.vpc_id

  tags = merge({

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

#
# Shared Server Security Group
#
resource "aws_security_group" "server" {
  name        = "${var.name}-server"
  description = "Shared ${var.name} server security group"
  vpc_id      = var.vpc_id

  tags = merge({

  }, var.tags)
}

resource "aws_security_group_rule" "server_cp" {
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  security_group_id = aws_security_group.server.id
  type              = "ingress"
  //  source_security_group_id = module.cp_lb.sg
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "server_cp_supervisor" {
  from_port         = 9345
  to_port           = 9345
  protocol          = "tcp"
  security_group_id = aws_security_group.server.id
  type              = "ingress"
  //  source_security_group_id = module.cp_lb.sg
  cidr_blocks = ["0.0.0.0/0"]
}