output "cluster_name" {
  description = "Name of the rke2 cluster"
  value       = local.uname
}

output "cluster_data" {
  description = "Map of cluster data required by agent pools for joining cluster, do not modify this"
  value       = local.cluster_data
}