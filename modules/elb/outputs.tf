//output "sg" {
//  value = aws_elb.controlplane.source_security_group_id
//}

output "dns" {
  value = aws_elb.controlplane.dns_name
}

output "id" {
  value = aws_elb.controlplane.id
}

output "name" {
  value = aws_elb.controlplane.name
}

output "security_group" {
  value = aws_security_group.controlplane.id
}