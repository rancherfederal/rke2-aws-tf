locals {
  # Create a unique cluster name we'll prefix to all resources created and ensure it's lowercase
  uname = var.unique_suffix ? lower("${var.cluster_name}-${random_string.uid.result}") : lower(var.cluster_name)

  default_tags = {
    "ClusterType" = "rke2",
  }

  ccm_tags = {
    "kubernetes.io/cluster/${local.uname}" = "owned"
  }

  cluster_data = {
    name       = local.uname
    server_url = module.cp_lb.dns
    cluster_sg = aws_security_group.cluster.id
    token      = module.statestore.token
  }
  security_groups = concat([aws_security_group.server.id, aws_security_group.cluster.id, module.cp_lb.security_group], var.extra_security_group_ids)
  target_groups   = concat(module.cp_lb.target_groups, var.extra_target_group_arns)
}

resource "random_string" "uid" {
  # NOTE: Don't get too crazy here, several aws resources have tight limits on lengths (such as load balancers), in practice we are also relying on users to uniquely identify their cluster names
  length  = 3
  special = false
  lower   = true
  upper   = false
  numeric = true
}

#
# Cluster join token
#
resource "random_password" "token" {
  length  = 40
  special = false
}

module "statestore" {
  source = "./modules/statestore"
  name   = local.uname
  token  = random_password.token.result
  tags   = merge(local.default_tags, var.tags)
}

#
# Controlplane Load Balancer
#
module "cp_lb" {
  source  = "./modules/loadbalancing"
  name    = local.uname
  vpc_id  = var.vpc_id
  subnets = var.subnets

  enable_cross_zone_load_balancing = var.controlplane_enable_cross_zone_load_balancing
  internal                         = var.controlplane_internal
  access_logs_bucket               = var.controlplane_access_logs_bucket

  cp_ingress_cidr_blocks            = var.controlplane_allowed_cidrs
  cp_supervisor_ingress_cidr_blocks = var.controlplane_allowed_cidrs

  tags = merge({}, local.default_tags, local.default_tags, var.tags)
}

#
# Security Groups
#

# Shared Cluster Security Group
resource "aws_security_group" "cluster" {
  name        = "${local.uname}-rke2-cluster"
  description = "Shared ${local.uname} cluster security group"
  vpc_id      = var.vpc_id

  tags = merge({
    "shared" = "true",
  }, local.default_tags, var.tags)
}

resource "aws_security_group_rule" "cluster_shared" {
  description       = "Allow all inbound traffic between ${local.uname} cluster nodes"
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

# Server Security Group
resource "aws_security_group" "server" {
  name        = "${local.uname}-rke2-server"
  vpc_id      = var.vpc_id
  description = "${local.uname} rke2 server node pool"
  tags        = merge(local.default_tags, var.tags)
}

resource "aws_security_group_rule" "server_cp" {
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.server.id
  type                     = "ingress"
  source_security_group_id = module.cp_lb.security_group
}

resource "aws_security_group_rule" "server_cp_supervisor" {
  from_port                = 9345
  to_port                  = 9345
  protocol                 = "tcp"
  security_group_id        = aws_security_group.server.id
  type                     = "ingress"
  source_security_group_id = module.cp_lb.security_group
}

#
# IAM Role
#
module "iam" {
  count = var.iam_instance_profile == "" ? 1 : 0

  source = "./modules/policies"
  name   = "${local.uname}-rke2-server"

  permissions_boundary = var.iam_permissions_boundary

  tags = merge({}, local.default_tags, var.tags)
}

#
# Policies
#
resource "aws_iam_role_policy" "aws_required" {
  count = var.iam_instance_profile == "" ? 1 : 0

  name   = "${local.uname}-rke2-server-aws-introspect"
  role   = module.iam[count.index].role
  policy = data.aws_iam_policy_document.aws_required[count.index].json
}

resource "aws_iam_role_policy" "aws_ccm" {
  count = var.iam_instance_profile == "" && var.enable_ccm ? 1 : 0

  name   = "${local.uname}-rke2-server-aws-ccm"
  role   = module.iam[count.index].role
  policy = data.aws_iam_policy_document.aws_ccm[count.index].json
}

resource "aws_iam_role_policy" "get_token" {
  count = var.iam_instance_profile == "" ? 1 : 0

  name   = "${local.uname}-rke2-server-get-token"
  role   = module.iam[count.index].role
  policy = module.statestore.token.policy_document
}

resource "aws_iam_role_policy" "put_kubeconfig" {
  count = var.iam_instance_profile == "" ? 1 : 0

  name   = "${local.uname}-rke2-server-put-kubeconfig"
  role   = module.iam[count.index].role
  policy = module.statestore.kubeconfig_put_policy
}

#
# Leader Nodepool
#
module "leader" {
  source = "./modules/nodepool"
  name   = "${local.uname}-leader"

  vpc_id                      = var.vpc_id
  subnets                     = var.subnets
  ami                         = var.ami
  instance_type               = var.instance_type
  block_device_mappings       = var.block_device_mappings
  extra_block_device_mappings = var.extra_block_device_mappings
  vpc_security_group_ids      = local.security_groups
  spot                        = var.spot
  target_group_arns           = local.target_groups

  # Overrideable variables
  userdata             = data.cloudinit_config.this[0].rendered
  iam_instance_profile = var.iam_instance_profile == "" ? module.iam[0].iam_instance_profile : var.iam_instance_profile

  # Don't allow something not recommended within etcd scaling, set max deliberately and only control desired
  asg = { min : 1, max : 1, desired : 1 }

  min_elb_capacity = 1

  tags = merge({
    "Role" = "leader",
  }, local.ccm_tags, var.tags)
}

# need to wait for leader to exist in cluster OR until # servers == expected # (for when user might re-apply the config)
resource "null_resource" "wait_for_leader_to_register" {
  provisioner "local-exec" {
    command = <<-EOT
    timeout --preserve-status 7m bash -c -- 'until [ "$${nodes}" = "1" ] || [ "$${nodes}" = "${var.servers}" ]; do
        sleep 5
        nodes="$(kubectl --kubeconfig <(echo $KUBECONFIG | base64 --decode) get nodes --no-headers | wc -l | awk '\''{$1=$1;print}'\'')"
        echo "rke2 nodes: $${nodes}"
    done'
    EOT
    environment = {
      KUBECONFIG = base64encode(data.aws_s3_object.kube_config.body)
    }
  }

  depends_on = [
    module.leader
  ]
}

#
# Server Nodepool
#
module "servers" {
  count  = var.servers > 1 ? 1 : 0
  source = "./modules/nodepool"
  name   = "${local.uname}-server"

  vpc_id                      = var.vpc_id
  subnets                     = var.subnets
  ami                         = var.ami
  instance_type               = var.instance_type
  block_device_mappings       = var.block_device_mappings
  extra_block_device_mappings = var.extra_block_device_mappings
  vpc_security_group_ids      = local.security_groups
  spot                        = var.spot

  # Overrideable variables
  userdata             = data.cloudinit_config.this[1].rendered
  iam_instance_profile = var.iam_instance_profile == "" ? module.iam[0].iam_instance_profile : var.iam_instance_profile

  # Don't allow something not recommended within etcd scaling, set max deliberately and only control desired
  asg = { min : 1, max : 7, desired : tonumber("${var.servers - 1}") }

  tags = merge({
    "Role" = "server",
  }, local.ccm_tags, var.tags)

  depends_on = [
    null_resource.wait_for_leader_to_register
  ]
}

#
# Wait for cluster nodes to reach expected number
#
resource "null_resource" "wait_for_servers_to_register" {
  count = var.servers > 1 ? 1 : 0
  provisioner "local-exec" {
    command = <<-EOT
    timeout --preserve-status 7m bash -c -- 'until [ "$${nodes}" = "${var.servers}" ]; do
        sleep 5
        nodes="$(kubectl --kubeconfig <(echo $KUBECONFIG | base64 --decode) get nodes --no-headers | wc -l | awk '\''{$1=$1;print}'\'')"
        echo "rke2 nodes: $${nodes}"
    done'
    EOT
    environment = {
      KUBECONFIG = base64encode(data.aws_s3_object.kube_config.body)
    }
  }

  depends_on = [
    module.servers
  ]
}

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  count                  = var.servers > 1 ? length(local.target_groups) : 0
  autoscaling_group_name = module.servers[0].asg_name
  lb_target_group_arn    = local.target_groups[count.index]

  depends_on = [
    null_resource.wait_for_servers_to_register
  ]
}

resource "null_resource" "wait_for_ingress" {
  provisioner "local-exec" {
    command = <<-EOT
      timeout --preserve-status 5m bash -c -- 'kubectl --kubeconfig <(echo $KUBECONFIG | base64 --decode) -n kube-system wait --for=condition=complete job/helm-install-rke2-ingress-nginx'
    EOT
    environment = {
      KUBECONFIG = base64encode(data.aws_s3_object.kube_config.body)
    }
  }

  depends_on = [
    null_resource.wait_for_leader_to_register,
    null_resource.wait_for_servers_to_register
  ]
}
