provider "aws" {
  region = "us-gov-west-1"
}

locals {
  name = "cloud-enabled"

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

# IAM Policies
module "policies" {
  source = "../../modules/policies"
  name   = local.name
}

#
# Server
#
module "server_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 2.0"

  create_role             = true
  role_name               = "${local.name}-server-role"
  trusted_role_services   = ["ec2.amazonaws.com"]
  role_requires_mfa       = false
  create_instance_profile = true


  custom_role_policy_arns = [
    module.policies.server_aws_policy_arn,
    module.policies.server_state_policy_arn,
  ]
}

module "rke2" {
  source = "../.."

  name    = local.name
  vpc_id  = data.aws_vpc.default.id
  subnets = [data.aws_subnet.default.id]

  ssh_authorized_keys  = [tls_private_key.ssh.public_key_openssh]
  ami                  = data.aws_ami.rhel7.image_id
  server_count         = 1
  iam_instance_profile = module.server_role.this_iam_instance_profile_name

  rke2_config = <<-EOT
cloud-provider-name: "aws"
EOT

  tags = local.tags
}

#
# Generic agent pool
#
module "agent_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 2.0"

  create_role             = true
  role_name               = "${local.name}-generic-agent-role"
  trusted_role_services   = ["ec2.amazonaws.com"]
  role_requires_mfa       = false
  create_instance_profile = true

  custom_role_policy_arns = [
    module.policies.agent_aws_policy_arn,
  ]
}

module "agents" {
  source  = "../../modules/agent-nodepool"
  name    = "generic-agent"
  vpc_id  = data.aws_vpc.default.id
  subnets = [data.aws_subnet.default.id]

  ami                  = data.aws_ami.rhel7.image_id
  ssh_authorized_keys  = [tls_private_key.ssh.public_key_openssh]
  spot                 = true
  iam_instance_profile = module.agent_role.this_iam_instance_profile_name

  rke2_config = <<-EOT
cloud-provider-name: "aws"
node-label:
  - "name=generic-agent"
EOT

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