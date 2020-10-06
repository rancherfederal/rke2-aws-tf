provider "aws" {
  region = local.aws_region
}

locals {
  name       = "quickstart"
  aws_region = "us-gov-west-1"

  tags = {
    "terraform" = "true",
    "env"       = "quickstart",
  }
}

# Query for defaults
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  availability_zone = "${local.aws_region}a"
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

# Private Key
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "pem" {
  filename        = "${local.name}.pem"
  content         = tls_private_key.ssh.private_key_pem
  file_permission = "0600"
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
  ssh_authorized_keys = [tls_private_key.ssh.public_key_openssh]

  tags = local.tags
}

#
# Generic Agent Pool
#
module "agents" {
  source = "../../modules/agent-nodepool"

  name                = "agent"
  vpc_id              = data.aws_vpc.default.id
  subnets             = [data.aws_subnet.default.id]
  ami                 = data.aws_ami.rhel7.image_id
  ssh_authorized_keys = [tls_private_key.ssh.public_key_openssh]
  asg                 = { min : 1, max : 5, desired : 2 }
  tags                = local.tags

  cluster_data = module.rke2.cluster_data
}

// For demonstration only, lock down ssh access in production
resource "aws_security_group_rule" "quickstart_ssh" {
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = module.rke2.cluster_data.cluster_sg
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

output "rke2" {
  value = module.rke2
}
