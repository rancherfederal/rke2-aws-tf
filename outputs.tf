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

output "server_url" {
  value = local.cluster_data.server_url
}

output "server_sg" {
  value = aws_security_group.server.id
}

output "server_nodepool_id" {
  value = module.servers.asg_id
}

output "server_nodepool_name" {
  value = module.servers.asg_name
}

output "server_nodepool_arn" {
  value = module.servers.asg_arn
}

output "iam_role" {
  description = "IAM role of server nodes"
  value       = var.iam_instance_profile == "" ? module.iam[0].role : var.iam_instance_profile
}

output "iam_instance_profile" {
  description = "IAM instance profile attached to server nodes"
  value       = var.iam_instance_profile == "" ? module.iam[0].iam_instance_profile : var.iam_instance_profile
}

output "iam_role_arn" {
  description = "IAM role arn of server nodes"
  value       = var.iam_instance_profile == "" ? module.iam[0].role_arn : var.iam_instance_profile
}

output "kubeconfig_path" {
  value = "s3://${module.statestore.bucket}/rke2.yaml"
}
