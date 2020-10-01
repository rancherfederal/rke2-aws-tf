//output "sg" {
//  value = aws_elb.controlplane.source_security_group_id
//}

output "dns" {
  value = aws_lb.controlplane.dns_name
}

output "id" {
  value = aws_lb.controlplane.id
}

output "name" {
  value = aws_lb.controlplane.name
}

output "server_tg_arn" {
  value = aws_lb_target_group.server.arn
}

output "server_supervisor_tg_arn" {
  value = aws_lb_target_group.server_supervisor.arn
}