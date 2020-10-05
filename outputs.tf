output "cluster_name" {
  value = var.name
}

output "server_url" {
  value = "https://${module.cp_lb.dns}:9345"
}

output "cluster_data" {
  value = local.cluster_data
}