output "dns" {
  value = aws_lb.controlplane.dns_name
}

output "id" {
  value = aws_lb.controlplane.id
}

output "arn" {
  value = aws_lb.controlplane.arn
}

output "name" {
  value = aws_lb.controlplane.name
}

output "security_group" {
  value = var.security_group_controlplane == "" ? aws_security_group.controlplane[0].id : var.security_group_controlplane
}

output "target_group_arns" {
  value = [aws_lb_target_group.apiserver.arn, aws_lb_target_group.supervisor.arn]
}