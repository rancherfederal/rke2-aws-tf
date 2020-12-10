output "iam_instance_profile" {
  value = aws_iam_instance_profile.this.name
}

output "role" {
  value = aws_iam_role.this.name
}

output "role_arn" {
  value = aws_iam_role.this.arn
}
