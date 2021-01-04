output "security_group" {
  value = module.nodepool.security_group
}

output "nodepool_name" {
  value = module.nodepool.asg_name
}

output "nodepool_arn" {
  value = module.nodepool.asg_arn
}

output "nodepool_id" {
  value = module.nodepool.asg_id
}

output "iam_role" {
  description = "IAM role of node pool"
  value       = var.iam_instance_profile == "" ? module.iam[0].role : var.iam_instance_profile
}

output "iam_instance_profile" {
  description = "IAM instance profile attached to nodes in nodepool"
  value       = var.iam_instance_profile == "" ? module.iam[0].iam_instance_profile : var.iam_instance_profile
}

output "iam_role_arn" {
  description = "IAM role arn of node pool"
  value       = var.iam_instance_profile == "" ? module.iam[0].role_arn : var.iam_instance_profile
}
