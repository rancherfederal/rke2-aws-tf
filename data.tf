data "template_cloudinit_config" "this" {
  count = var.server_count

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
    filename     = "00_cfg.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/files/server.sh", {
      server_index = count.index
      server       = "https://${module.cp_lb.dns}:9345"

      args = {
        "write-kubeconfig-mode" = var.write_kubeconfig_mode
        "token"                 = random_password.token.result
      }

      list_args = {
        "tls-san"                     = [module.cp_lb.dns]
        "node-label"                  = var.node_labels
        "node-taint"                  = var.node_taints
        "kube-apiserver-arg"          = var.kube_apiserver_args
        "kube-scheduler-arg"          = var.kube_scheduler_args
        "kube-controller-manager-arg" = var.kube_controller_manager_args
      }
    })
  }

  part {
    filename     = "01_rke2.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/common/rke2.sh", {
      type = "server"
    })
  }
}
