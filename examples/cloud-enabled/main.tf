provider "aws" {
  region = local.aws_region
  default_tags {
    tags = local.tags
  }
}

locals {
  cluster_name = "cloud-enabled"
  aws_region   = "us-gov-west-1"
  cidr         = "10.88.0.0/16"
  ssh_allowed_cidrs = [
    "0.0.0.0/0"
  ]

  tags = {
    "terraform" = "true",
    "env"       = "cloud-enabled",
  }
}

data "aws_ami" "rhel8" {
  most_recent = true
  owners      = ["219670896067"] # owner is specific to aws gov cloud

  filter {
    name   = "name"
    values = ["RHEL-8*"]
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

resource "local_sensitive_file" "ssh_pem" {
  filename        = "${local.cluster_name}.pem"
  content         = tls_private_key.ssh.private_key_pem
  file_permission = "0600"
}

#
# Network
#
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "rke2-${local.cluster_name}"
  cidr = local.cidr

  azs             = ["${local.aws_region}a", "${local.aws_region}b", "${local.aws_region}c"]
  public_subnets  = [cidrsubnet(local.cidr, 8, 1), cidrsubnet(local.cidr, 8, 2), cidrsubnet(local.cidr, 8, 3)]
  private_subnets = [cidrsubnet(local.cidr, 8, 101), cidrsubnet(local.cidr, 8, 102), cidrsubnet(local.cidr, 8, 103)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_vpn_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Note that EC2s launched into a public subnet that do not have a public IP
  # address will not be able to access the Internet because public subnets
  # do not get NAT gateways
  map_public_ip_on_launch = true

  # Add in required tags for proper AWS CCM integration
  public_subnet_tags = merge({
    "kubernetes.io/cluster/${module.rke2.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                            = "1"
  }, local.tags)

  private_subnet_tags = merge({
    "kubernetes.io/cluster/${module.rke2.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"                   = "1"
  }, local.tags)

  tags = merge({
    "kubernetes.io/cluster/${module.rke2.cluster_name}" = "shared"
  }, local.tags)
}

#
# Server
#
module "rke2" {
  source = "../.."

  cluster_name = local.cluster_name
  vpc_id       = module.vpc.vpc_id
  subnets      = module.vpc.public_subnets # Note: Public subnets used for demo purposes, this is not recommended in production

  ami                   = data.aws_ami.rhel8.image_id
  ssh_authorized_keys   = [tls_private_key.ssh.public_key_openssh]
  instance_type         = "t3.medium"
  controlplane_internal = false # Note this defaults to best practice of true, but is explicitly set to public for demo purposes
  servers               = 1

  # Enable AWS Cloud Controller Manager
  enable_ccm        = true
  enable_autoscaler = true

  rke2_config = yamlencode({ "node-label" : ["name=server", "os=rhel8"] })

  rke2_channel = "v1.27"
}

#
# Generic agent pool
#
module "agents" {
  source = "../../modules/agent-nodepool"

  name    = "generic"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets # Note: Public subnets used for demo purposes, this is not recommended in production

  ami                 = data.aws_ami.rhel8.image_id
  ssh_authorized_keys = [tls_private_key.ssh.public_key_openssh]
  spot                = true
  asg                 = { min : 1, max : 10, desired : 2 }
  instance_type       = "t3.large"

  # Enable AWS Cloud Controller Manager and Cluster Autoscaler
  enable_ccm        = true
  enable_autoscaler = true

  rke2_config = yamlencode({ "node-label" : ["name=generic", "os=rhel8"] })

  cluster_data = module.rke2.cluster_data

  rke2_channel = "v1.27"
}

# For demonstration only, lock down ssh access in production
resource "aws_security_group_rule" "quickstart_ssh" {
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = module.rke2.cluster_data.cluster_sg
  type              = "ingress"
  cidr_blocks       = local.ssh_allowed_cidrs
}

# Generic outputs as examples
output "rke2" {
  value = module.rke2
}

# Example method of fetching kubeconfig from state store, requires aws cli and bash locally
resource "null_resource" "kubeconfig" {
  depends_on = [module.rke2]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "aws s3 cp ${module.rke2.kubeconfig_path} rke2.yaml"
  }
}