provider "aws" {
  region = local.aws_region
}

locals {
  cluster_name = "quickstart"
  aws_region   = "us-gov-west-1"

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

# Private Key
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "pem" {
  filename        = "${local.cluster_name}.pem"
  content         = tls_private_key.ssh.private_key_pem
  file_permission = "0600"
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

#
# Server
#
module "rke2" {
  source = "../.."

  cluster_name          = local.cluster_name
  vpc_id                = data.aws_vpc.default.id
  subnets               = [data.aws_subnet.default.id]
  ami                   = data.aws_ami.rhel8.image_id
  ssh_authorized_keys   = [tls_private_key.ssh.public_key_openssh]
  controlplane_internal = false # Note this defaults to best practice of true, but is explicitly set to public for demo purposes

  tags = local.tags
}

#
# Generic Agent Pool
#
module "agents" {
  source = "../../modules/agent-nodepool"

  name                = "generic"
  vpc_id              = data.aws_vpc.default.id
  subnets             = [data.aws_subnet.default.id]
  ami                 = data.aws_ami.rhel8.image_id
  ssh_authorized_keys = [tls_private_key.ssh.public_key_openssh]
  tags                = local.tags

  cluster_data = module.rke2.cluster_data
}

# For demonstration only, lock down ssh access in production
resource "aws_security_group_rule" "quickstart_ssh" {
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = module.rke2.cluster_data.cluster_sg
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
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
