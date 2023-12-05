<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_launch_template.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami"></a> [ami](#input\_ami) | n/a | `string` | `""` | no |
| <a name="input_asg"></a> [asg](#input\_asg) | n/a | <pre>object({<br>    min                  = number<br>    max                  = number<br>    desired              = number<br>    suspended_processes  = list(string)<br>    termination_policies = list(string)<br>  })</pre> | <pre>{<br>  "desired": 3,<br>  "max": 7,<br>  "min": 1,<br>  "suspended_processes": [],<br>  "termination_policies": []<br>}</pre> | no |
| <a name="input_associate_public_ip_address"></a> [associate\_public\_ip\_address](#input\_associate\_public\_ip\_address) | n/a | `bool` | `null` | no |
| <a name="input_block_device_mappings"></a> [block\_device\_mappings](#input\_block\_device\_mappings) | n/a | `map(string)` | <pre>{<br>  "size": 30,<br>  "type": "gp2"<br>}</pre> | no |
| <a name="input_extra_block_device_mappings"></a> [extra\_block\_device\_mappings](#input\_extra\_block\_device\_mappings) | n/a | `list(map(string))` | `[]` | no |
| <a name="input_extra_cloud_config_config"></a> [extra\_cloud\_config\_config](#input\_extra\_cloud\_config\_config) | extra config to append to cloud-config | `string` | `""` | no |
| <a name="input_health_check_type"></a> [health\_check\_type](#input\_health\_check\_type) | n/a | `string` | `"EC2"` | no |
| <a name="input_iam_instance_profile"></a> [iam\_instance\_profile](#input\_iam\_instance\_profile) | n/a | `string` | `""` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | n/a | `string` | `"t3.medium"` | no |
| <a name="input_load_balancers"></a> [load\_balancers](#input\_load\_balancers) | n/a | `list(string)` | `[]` | no |
| <a name="input_metadata_options"></a> [metadata\_options](#input\_metadata\_options) | Instance Metadata Options | `map(any)` | n/a | yes |
| <a name="input_min_elb_capacity"></a> [min\_elb\_capacity](#input\_min\_elb\_capacity) | n/a | `number` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | n/a | yes |
| <a name="input_spot"></a> [spot](#input\_spot) | n/a | `bool` | `false` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | n/a | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | `{}` | no |
| <a name="input_target_group_arns"></a> [target\_group\_arns](#input\_target\_group\_arns) | n/a | `list(string)` | `[]` | no |
| <a name="input_userdata"></a> [userdata](#input\_userdata) | n/a | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `string` | n/a | yes |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | n/a | `list(string)` | `[]` | no |
| <a name="input_wait_for_capacity_timeout"></a> [wait\_for\_capacity\_timeout](#input\_wait\_for\_capacity\_timeout) | How long Terraform should wait for ASG instances to be healthy before timing out. | `string` | `"10m"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_asg_arn"></a> [asg\_arn](#output\_asg\_arn) | n/a |
| <a name="output_asg_id"></a> [asg\_id](#output\_asg\_id) | n/a |
| <a name="output_asg_name"></a> [asg\_name](#output\_asg\_name) | n/a |
| <a name="output_launch_template_id"></a> [launch\_template\_id](#output\_launch\_template\_id) | n/a |
| <a name="output_launch_template_name"></a> [launch\_template\_name](#output\_launch\_template\_name) | n/a |
| <a name="output_security_group"></a> [security\_group](#output\_security\_group) | n/a |
<!-- END_TF_DOCS -->