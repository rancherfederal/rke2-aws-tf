output "security_group" {
  value = aws_security_group.this.id
}

output "nodepool_id" {
  value = module.nodepool.asg_id
}

output "nodepool_name" {
  value = module.nodepool.asg_name
}

output "nodepool_arn" {
  value = module.nodepool.asg_arn
}