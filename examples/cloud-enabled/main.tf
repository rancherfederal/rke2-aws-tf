provider "aws" {
  region = local.aws_region
}

locals {
  name       = "cloud-enabled"
  aws_region = "us-gov-west-1"

  tags = {
    "terraform" = "true",
    "env"       = "cloud-enabled",
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

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_ami" "rhel8" {
  most_recent = true
  owners      = ["219670896067"]

  filter {
    name   = "name"
    values = ["RHEL-8*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_ami" "centos7" {
  most_recent = true
  owners      = ["345084742485"]

  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_ami" "ubuntu" {
  owners      = ["513442679011"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu*-20.04*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_ami" "centos7" {
  owners      = ["679593333241"]
  most_recent = true

  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Key Pair
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_pem" {
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
  ami                 = data.aws_ami.centos7.image_id # Note: Multi OS is primarily for example purposes
  ssh_authorized_keys = [tls_private_key.ssh.public_key_openssh]
  asg                 = { min : 1, max : 5, desired : 3 }

  rke2_config = <<-EOT
cloud-provider-name: "aws"
node-label:
  - "name=server"
  - "os=ubuntu"
EOT

  tags = local.tags
}

#
# Generic agent pool
#
module "agents" {
  source = "../../modules/agent-nodepool"

  name                = "agent"
  vpc_id              = data.aws_vpc.default.id
  subnets             = [data.aws_subnet.default.id]
  ami                 = data.aws_ami.ubuntu.image_id # Note: Multi OS is primarily for example purposes
  ssh_authorized_keys = [tls_private_key.ssh.public_key_openssh]
  spot                = true
  asg                 = { min : 1, max : 1, desired : 1 }

  rke2_config = <<-EOT
cloud-provider-name: "aws"
node-label:
  - "name=generic-agent"
  - "os=ubuntu"
EOT

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