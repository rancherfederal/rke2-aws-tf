locals {
  fullname = "${var.cluster_data.name}-${var.name}"
  ccm_tags = {
    "Name"                                           = "${local.fullname}-rke2-nodepool",
    "kubernetes.io/cluster/${var.cluster_data.name}" = "owned",
  }
}

resource "aws_security_group" "this" {
  name        = "${local.fullname}-rke2-nodepool"
  vpc_id      = var.vpc_id
  description = "${var.name} node pool"
  tags        = merge(local.ccm_tags, var.tags)
}

#
# IAM Role
#
# Required IAM Policy for AWS CCM
data "aws_iam_policy_document" "aws_ccm" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:BatchGetImage",
      "autoscaling:DescribeTags",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
    ]
  }
}

module "iam" {
  count = var.iam_instance_profile == "" ? 1 : 0

  source = "../policies"
  name   = local.fullname
  policies = [
    {
      name   = "${local.fullname}-aws-ccm",
      policy = data.aws_iam_policy_document.aws_ccm.json,
    },
    {
      name   = "${local.fullname}-get-token",
      policy = var.cluster_data.token.policy_document,
    }
  ]
}

#
# Launch template
#
resource "aws_launch_template" "this" {
  name                   = "${local.fullname}-rke2-nodepool"
  image_id               = var.ami
  instance_type          = var.instance_type
  user_data              = var.userdata == "" ? data.template_cloudinit_config.init.rendered : var.userdata
  vpc_security_group_ids = concat([aws_security_group.this.id], [var.cluster_data.cluster_sg], var.vpc_security_group_ids)

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_type           = lookup(var.block_device_mappings, "type", null)
      volume_size           = lookup(var.block_device_mappings, "size", null)
      iops                  = lookup(var.block_device_mappings, "iops", null)
      kms_key_id            = lookup(var.block_device_mappings, "kms_key_id", null)
      encrypted             = lookup(var.block_device_mappings, "encrypted", null)
      delete_on_termination = lookup(var.block_device_mappings, "delete_on_termination", null)
    }
  }

  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile == "" ? [module.iam[0].iam_instance_profile] : [var.iam_instance_profile]
    content {
      name = iam_instance_profile.value
    }
  }

  tags = merge(local.ccm_tags, var.tags)
}

#
# Autoscaling group
#
resource "aws_autoscaling_group" "this" {
  name                = "${local.fullname}-rke2-nodepool"
  vpc_zone_identifier = var.subnets

  min_size         = var.asg.min
  max_size         = var.asg.max
  desired_capacity = var.asg.desired

  # Health check and target groups dependent on whether we're a server or not (identified via rke2_url)
  health_check_type = var.health_check_type
  target_group_arns = var.target_group_arns

  min_elb_capacity = var.min_elb_capacity

  dynamic "launch_template" {
    for_each = var.spot ? [] : ["spot"]

    content {
      id      = aws_launch_template.this.id
      version = "$Latest"
    }
  }

  dynamic "mixed_instances_policy" {
    for_each = var.spot ? ["spot"] : []

    content {
      instances_distribution {
        on_demand_base_capacity                  = 0
        on_demand_percentage_above_base_capacity = 0
      }

      launch_template {
        launch_template_specification {
          launch_template_id   = aws_launch_template.this.id
          launch_template_name = aws_launch_template.this.name
          version              = "$Latest"
        }
      }
    }
  }

  dynamic "tag" {
    for_each = merge(local.ccm_tags, var.tags)

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
