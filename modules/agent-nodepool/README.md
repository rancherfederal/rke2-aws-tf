<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_cloudinit"></a> [cloudinit](#provider\_cloudinit) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_iam"></a> [iam](#module\_iam) | ../policies | n/a |
| <a name="module_init"></a> [init](#module\_init) | ../userdata | n/a |
| <a name="module_nodepool"></a> [nodepool](#module\_nodepool) | ../nodepool | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role_policy.aws_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.aws_ccm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.get_token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_policy_document.aws_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.aws_ccm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [cloudinit_config.init](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami"></a> [ami](#input\_ami) | Node pool ami | `string` | `""` | no |
| <a name="input_asg"></a> [asg](#input\_asg) | Node pool AutoScalingGroup scaling definition | <pre>object({<br>    min                  = number<br>    max                  = number<br>    desired              = number<br>    suspended_processes  = optional(list(string))<br>    termination_policies = optional(list(string))<br>  })</pre> | <pre>{<br>  "desired": 1,<br>  "max": 10,<br>  "min": 1,<br>  "suspended_processes": [],<br>  "termination_policies": [<br>    "Default"<br>  ]<br>}</pre> | no |
| <a name="input_awscli_url"></a> [awscli\_url](#input\_awscli\_url) | URL for awscli zip file | `string` | `"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"` | no |
| <a name="input_block_device_mappings"></a> [block\_device\_mappings](#input\_block\_device\_mappings) | Node pool block device mapping configuration | `map(string)` | <pre>{<br>  "size": 30,<br>  "type": "gp2"<br>}</pre> | no |
| <a name="input_ccm_external"></a> [ccm\_external](#input\_ccm\_external) | Set kubelet arg 'cloud-provider-name' value to 'external'.  Requires manual install of CCM. | `bool` | `false` | no |
| <a name="input_cluster_data"></a> [cluster\_data](#input\_cluster\_data) | Required data relevant to joining an existing rke2 cluster, sourced from main rke2 module, do NOT modify | <pre>object({<br>    name       = string<br>    server_url = string<br>    cluster_sg = string<br>    token = object({<br>      bucket          = string<br>      bucket_arn      = string<br>      object          = string<br>      policy_document = string<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_download"></a> [download](#input\_download) | Toggle best effort download of rke2 dependencies (rke2 and aws cli), if disabled, dependencies are assumed to exist in $PATH | `bool` | `true` | no |
| <a name="input_enable_autoscaler"></a> [enable\_autoscaler](#input\_enable\_autoscaler) | Toggle configure the nodepool for cluster autoscaler, this will ensure the appropriate IAM policies are present, you are still responsible for ensuring cluster autoscaler is installed | `bool` | `false` | no |
| <a name="input_enable_ccm"></a> [enable\_ccm](#input\_enable\_ccm) | Toggle enabling the cluster as aws aware, this will ensure the appropriate IAM policies are present | `bool` | `false` | no |
| <a name="input_extra_block_device_mappings"></a> [extra\_block\_device\_mappings](#input\_extra\_block\_device\_mappings) | Used to specify additional block device mapping configurations | `list(map(string))` | `[]` | no |
| <a name="input_extra_cloud_config_config"></a> [extra\_cloud\_config\_config](#input\_extra\_cloud\_config\_config) | extra config to append to cloud-config | `string` | `""` | no |
| <a name="input_extra_security_group_ids"></a> [extra\_security\_group\_ids](#input\_extra\_security\_group\_ids) | List of additional security group IDs | `list(string)` | `[]` | no |
| <a name="input_iam_instance_profile"></a> [iam\_instance\_profile](#input\_iam\_instance\_profile) | Node pool IAM Instance Profile, created if left blank (default behavior) | `string` | `""` | no |
| <a name="input_iam_permissions_boundary"></a> [iam\_permissions\_boundary](#input\_iam\_permissions\_boundary) | If provided, the IAM role created for the nodepool will be created with this permissions boundary attached. | `string` | `null` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Node pool instance type | `string` | `"t3.medium"` | no |
| <a name="input_metadata_options"></a> [metadata\_options](#input\_metadata\_options) | Instance Metadata Options | `map(any)` | <pre>{<br>  "http_endpoint": "enabled",<br>  "http_put_response_hop_limit": 2,<br>  "http_tokens": "required",<br>  "instance_metadata_tags": "disabled"<br>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | Nodepool name | `string` | n/a | yes |
| <a name="input_post_userdata"></a> [post\_userdata](#input\_post\_userdata) | Custom userdata to run immediately after rke2 node attempts to join cluster | `string` | `""` | no |
| <a name="input_pre_userdata"></a> [pre\_userdata](#input\_pre\_userdata) | Custom userdata to run immediately before rke2 node attempts to join cluster, after required rke2, dependencies are installed | `string` | `""` | no |
| <a name="input_rke2_channel"></a> [rke2\_channel](#input\_rke2\_channel) | Channel to use for RKE2 agent nodepool | `string` | `null` | no |
| <a name="input_rke2_config"></a> [rke2\_config](#input\_rke2\_config) | Node pool additional configuration passed as rke2 config file, see https://docs.rke2.io/install/install_options/agent_config for full list of options | `string` | `""` | no |
| <a name="input_rke2_install_script_url"></a> [rke2\_install\_script\_url](#input\_rke2\_install\_script\_url) | URL for RKE2 install script | `string` | `"https://get.rke2.io"` | no |
| <a name="input_rke2_start"></a> [rke2\_start](#input\_rke2\_start) | Start/Stop value for the rke2-server/agent service.  True=start, False= don't start. | `bool` | `true` | no |
| <a name="input_rke2_version"></a> [rke2\_version](#input\_rke2\_version) | Version to use for RKE2 agent nodepool | `string` | `null` | no |
| <a name="input_spot"></a> [spot](#input\_spot) | Toggle spot requests for node pool | `bool` | `false` | no |
| <a name="input_ssh_authorized_keys"></a> [ssh\_authorized\_keys](#input\_ssh\_authorized\_keys) | Node pool list of public keys to add as authorized ssh keys, not required | `list(string)` | `[]` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | List of subnet IDs to create resources in | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of additional tags to add to all resources created | `map(string)` | `{}` | no |
| <a name="input_unzip_rpm_url"></a> [unzip\_rpm\_url](#input\_unzip\_rpm\_url) | URL path to unzip rpm | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID to create resources in | `string` | n/a | yes |
| <a name="input_wait_for_capacity_timeout"></a> [wait\_for\_capacity\_timeout](#input\_wait\_for\_capacity\_timeout) | How long Terraform should wait for ASG instances to be healthy before timing out. | `string` | `"10m"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_iam_instance_profile"></a> [iam\_instance\_profile](#output\_iam\_instance\_profile) | IAM instance profile attached to nodes in nodepool |
| <a name="output_iam_role"></a> [iam\_role](#output\_iam\_role) | IAM role of node pool |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | IAM role arn of node pool |
| <a name="output_nodepool_arn"></a> [nodepool\_arn](#output\_nodepool\_arn) | n/a |
| <a name="output_nodepool_id"></a> [nodepool\_id](#output\_nodepool\_id) | n/a |
| <a name="output_nodepool_name"></a> [nodepool\_name](#output\_nodepool\_name) | n/a |
| <a name="output_security_group"></a> [security\_group](#output\_security\_group) | n/a |
<!-- END_TF_DOCS -->