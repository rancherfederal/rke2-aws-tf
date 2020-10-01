provider "aws" {
  region = "us-gov-west-1"
}

locals {
  name    = "quickstart"
  vpc_id  = "vpc-087496fba26c6d6df"
  subnets = ["subnet-084b8f063e166cd01", "subnet-0fc3993950d081bfb", "subnet-0b998c99f39ccf748"]

  ami = "ami-24206045"

  tags = {
    "terraform" = "true",
    "env"       = "quickstart",
  }
}

#
# Server
#
module "rke2" {
  source = "../.."

  name    = local.name
  vpc_id  = local.vpc_id
  subnets = local.subnets

  ssh_authorized_keys = [file("~/.ssh/id_rsa.pub")]
  ami                 = local.ami
  server_count        = 3

  tags = local.tags
}

#
# Generic agent pool
#
module "agents" {
  source  = "../../modules/agent-nodepool"
  cluster = module.rke2.cluster_name
  name    = "generic-agent"
  vpc_id  = local.vpc_id
  subnets = local.subnets

  ami                 = local.ami
  ssh_authorized_keys = [file("~/.ssh/id_rsa.pub")]

  server_url             = module.rke2.server_url
  token                  = module.rke2.token
  cluster_security_group = module.rke2.shared_cluster_sg
}

// For demonstration only, lock down ssh access in production
resource "aws_security_group_rule" "quickstart_ssh" {
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = module.rke2.shared_cluster_sg
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

output "rke2" {
  value = module.rke2
}