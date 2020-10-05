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

data "aws_ami" "centos8" {
  most_recent = true
  owners      = ["345084742485"]

  filter {
    name   = "name"
    values = ["CentOS Linux 8 x86_64 HVM EBS*"]
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

  filter {
    name   = "architecture"
    values = ["x86_64"]
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
# Network
#
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "rke2-${local.name}"
  cidr = "10.88.0.0/16"

  azs             = ["${local.aws_region}a", "${local.aws_region}b", "${local.aws_region}c"]
  public_subnets  = ["10.88.1.0/24", "10.88.2.0/24", "10.88.3.0/24"]
  private_subnets = ["10.88.101.0/24", "10.88.102.0/24", "10.88.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_vpn_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = merge({
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = "1"
  }, local.tags)

  private_subnet_tags = merge({
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = "1"
  }, local.tags)

  tags = merge({
    "kubernetes.io/cluster/${local.name}" = "shared"
  }, local.tags)
}

#
# Server
#
module "rke2" {
  source = "../.."

  name    = local.name
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets # Note: Public subnets used for demo purposes, this is not recommended in production

  ami                 = data.aws_ami.rhel8.image_id # Note: Multi OS is primarily for example purposes
  ssh_authorized_keys = [tls_private_key.ssh.public_key_openssh]
  asg                 = { min : 1, max : 5, desired : 1 }
  instance_type       = "t3a.medium"

  rke2_config = <<-EOT
cloud-provider-name: "aws"
node-label:
  - "name=server"
  - "os=rhel8"
EOT

  tags = local.tags
}

#
# Generic agent pool
#
module "agents" {
  source = "../../modules/agent-nodepool"

  name    = "agent"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets # Note: Public subnets used for demo purposes, this is not recommended in production

  ami                 = data.aws_ami.rhel8.image_id # Note: Multi OS is primarily for example purposes
  ssh_authorized_keys = [tls_private_key.ssh.public_key_openssh]
  spot                = true
  asg                 = { min : 1, max : 10, desired : 2 }
  instance_type       = "t3a.large"

  rke2_config = <<-EOT
cloud-provider-name: "aws"
node-label:
  - "name=generic-agent"
  - "os=rhel8"
EOT

  cluster_data = module.rke2.cluster_data

  tags = merge({
    "k8s.io/cluster-autoscaler/enabled"       = "true"
    "k8s.io/cluster-autoscaler/${local.name}" = "true"
  }, local.tags)
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