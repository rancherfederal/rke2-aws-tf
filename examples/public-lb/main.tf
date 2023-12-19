locals {
  cidr               = "10.0.0.0/16"
  cluster_name       = "public-lb"
  rke2_instance_type = "t3.medium"
  rke2_channel       = "stable"
  servers            = 3

  tags = {
    "terraform" = "true",
    "env"       = "public-lb",
  }
}

provider "aws" {
  default_tags {
    tags = local.tags
  }
}

data "aws_ami" "rhel9" {
  most_recent = true
  owners      = ["219670896067"] # owner is specific to aws gov cloud

  filter {
    name   = "name"
    values = ["RHEL-9*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_region" "current" {}

data "cloudinit_config" "bastion" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "00_init.sh"
    content_type = "text/x-shellscript"
    # required to use sshuttle for ssh tunneling
    content = <<EOF
#!/bin/sh
dnf install -y python3
EOF
  }
}

resource "aws_key_pair" "admin" {
  key_name   = local.cluster_name
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.rhel9.id
  associate_public_ip_address = true
  instance_type               = "t3.small"
  key_name                    = aws_key_pair.admin.key_name
  subnet_id                   = module.vpc.public_subnets[0]
  user_data                   = data.cloudinit_config.bastion.rendered
  vpc_security_group_ids      = [aws_security_group.bastion.id, module.rke2.cluster_sg]

  tags = {
    Name = "${module.rke2.cluster_data.name}-bastion"
  }
}

resource "aws_security_group" "bastion" {
  name        = "${module.rke2.cluster_data.name}-bastion"
  description = "Default sg for ${module.rke2.cluster_data.name}-bastion"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "ssh" {
  description = "Allow ssh from Internet"

  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.bastion.id
  type              = "ingress"
}

resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "local_sensitive_file" "pem" {
  filename        = "${module.rke2.cluster_name}.pem"
  content         = tls_private_key.ssh.private_key_openssh
  file_permission = "0600"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "rke2-${local.cluster_name}"
  cidr = local.cidr

  azs = [
    "${data.aws_region.current.name}a",
    "${data.aws_region.current.name}b",
    "${data.aws_region.current.name}c"
  ]
  public_subnets = [
    cidrsubnet(local.cidr, 8, 1),
    cidrsubnet(local.cidr, 8, 2),
    cidrsubnet(local.cidr, 8, 3)
  ]
  private_subnets = [
    cidrsubnet(local.cidr, 8, 101),
    cidrsubnet(local.cidr, 8, 102),
    cidrsubnet(local.cidr, 8, 103)
  ]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_vpn_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}

module "rke2" {
  source = "../.."

  ami                                           = data.aws_ami.rhel9.id
  cluster_name                                  = local.cluster_name
  controlplane_enable_cross_zone_load_balancing = true
  controlplane_internal                         = false
  lb_subnets                                    = module.vpc.public_subnets
  instance_type                                 = local.rke2_instance_type
  rke2_channel                                  = local.rke2_channel
  servers                                       = local.servers
  subnets                                       = module.vpc.private_subnets
  ssh_authorized_keys                           = [tls_private_key.ssh.public_key_openssh]
  tags                                          = local.tags
  vpc_id                                        = module.vpc.vpc_id

  # kube prereqs not present in RHEL 9
  pre_userdata = <<EOF
#!/bin/sh
dnf install -y conntrack container-selinux iptables-nft socat
EOF
}

output "cluster_data" {
  value = module.rke2
}

output "bastion_ip" {
  value = aws_instance.bastion.public_ip
}

output "vpc_cidr" {
  value = local.cidr
}
