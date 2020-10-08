output "cluster_name" {
  description = "Name of the rke2 cluster"
  value       = local.uname
}

# This output is intentionaly blackboxed from the user, make separate outputs intended for user consumption
output "cluster_data" {
  description = "Map of cluster data required by agent pools for joining cluster, do not modify this"
  value       = local.cluster_data
}

output "cluster_sg" {
  description = "Security group shared by cluster nodes, this is different than nodepool security groups"
  value       = local.cluster_data.cluster_sg
}

output "server_dns" {
  value = local.cluster_data.server_dns
}

output "server_sg" {
  value = module.servers.security_group
}

output "server_nodepool_id" {
  value = module.servers.nodepool_id
}

output "server_nodepool_name" {
  value = module.servers.nodepool_name
}