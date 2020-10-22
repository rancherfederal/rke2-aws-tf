output "templated" {
  value = data.template_file.init.rendered
}