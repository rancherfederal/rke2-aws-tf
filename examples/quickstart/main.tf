provider "aws" {
  region = "us-gov-west-1"
}

locals {
  name = "quickstart"

  tags = {
    "terraform" = "true",
    "env"       = "quickstart",
  }
}

# Defaults
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  availability_zone = "us-gov-west-1a"
  default_for_az    = true
}

data "aws_ami" "rhel7" {
  most_recent = true
  owners      = ["219670896067"]

  filter {
    name   = "name"
    values = ["RHEL-7*"]
  }
}

#
# Server
#
module "rke2" {
  source = "../.."

  name                = local.name
  vpc_id              = data.aws_vpc.default.id
  subnets             = [data.aws_subnet.default.id]
  ami                 = data.aws_ami.rhel7.image_id
  server_count        = 3
  ssh_authorized_keys = [file("~/.ssh/id_rsa.pub")]

  tags = local.tags
}

#
# Generic Agent Pool
#
module "agents" {
  source = "../../modules/agent-nodepool"

  name                = "generic-agent"
  vpc_id              = data.aws_vpc.default.id
  subnets             = [data.aws_subnet.default.id]
  ami                 = data.aws_ami.rhel7.image_id
  ssh_authorized_keys = [file("~/.ssh/id_rsa.pub")]

  cluster_data = module.rke2.cluster_data
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
