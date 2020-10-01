locals {
  tags = merge({
    "Name"                                 = "${var.cluster}-${var.name}-nodepool",
    "kubernetes.io/cluster/${var.cluster}" = "owned"
  }, var.tags)
}


resource "aws_security_group" "this" {
  name        = "${var.name}-k3s-nodepool"
  vpc_id      = var.vpc_id
  description = "${var.name} node pool"
  tags        = local.tags
}


#
# Launch template
#
resource "aws_launch_template" "this" {
  name                   = "${var.name}-k3s-nodepool"
  image_id               = var.ami
  instance_type          = var.instance_type
  user_data              = data.template_cloudinit_config.this.rendered
  vpc_security_group_ids = concat([aws_security_group.this.id], [var.cluster_security_group], var.extra_security_groups)

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = var.block_device_mappings.size
      encrypted             = var.block_device_mappings.encrypted
      delete_on_termination = true
    }
  }

  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile != "" ? [var.iam_instance_profile] : []
    content {
      name = iam_instance_profile.value
    }
  }

  tags = local.tags
}

#
# Autoscaling group
#
resource "aws_autoscaling_group" "this" {
  name                = "${var.name}-k3s-nodepool"
  vpc_zone_identifier = var.subnets

  min_size         = var.asg.min
  max_size         = var.asg.max
  desired_capacity = var.asg.desired

  # Health check and target groups dependent on whether we're a server or not (identified via k3s_url)
  health_check_type = "EC2"

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
    for_each = local.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}