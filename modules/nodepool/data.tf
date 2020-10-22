module "init" {
  source = "../userdata"

  server_url   = var.cluster_data.server_url
  token_bucket = var.cluster_data.token.bucket
}

data "template_cloudinit_config" "init" {
  gzip          = true
  base64_encode = true

  # Main cloud-init config file
  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/files/cloud-config.yaml", {
      ssh_authorized_keys = var.ssh_authorized_keys
    })
  }

  part {
    filename     = "00_download.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/../common/download.sh", {
      # Must not use `version` here since that is reserved
      rke2_version = var.rke2_version
      type         = "agent"
    })
  }

  part {
    filename     = "01_rke2.sh"
    content_type = "text/x-shellscript"
    content      = module.init.templated
  }
}

# Required IAM Policy for AWS CCM
data "aws_iam_policy_document" "aws_ccm" {
  count = var.iam_instance_profile == null ? 1 : 0

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
