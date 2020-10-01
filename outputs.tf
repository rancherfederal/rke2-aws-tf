output "cluster_name" {
  value = var.name
}

output "shared_cluster_sg" {
  value = aws_security_group.cluster.id
}

output "shared_server_sg" {
  value = aws_security_group.server.id
}

output "server_public_ips" {
  value = aws_instance.servers.*.public_ip
}

output "server_private_ips" {
  value = aws_instance.servers.*.private_ip
}

output "server_url" {
  value = "https://${module.cp_lb.dns}:9345"
}

output "token" {
  value = random_password.token.result
}

output "cluster_data" {
  value = {
    name                   = var.name
    server_url             = "https://${module.cp_lb.dns}:9345"
    cluster_security_group = aws_security_group.cluster.id
    token                  = random_password.token.result
  }
}