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
  value       = module.iam.role
}

output "iam_instance_profile" {
  description = "IAM instance profile attached to nodes in nodepool"
  value       = module.iam.iam_instance_profile
}