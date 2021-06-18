## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13, < 0.14 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ami | Node pool ami | `string` | `""` | no |
| asg | Node pool AutoScalingGroup scaling definition | <pre>object({<br>    min     = number<br>    max     = number<br>    desired = number<br>  })</pre> | <pre>{<br>  "desired": 1,<br>  "max": 10,<br>  "min": 1<br>}</pre> | no |
| block\_device\_mappings | Node pool block device mapping configuration | `map(string)` | <pre>{<br>  "size": 30,<br>  "type": "gp2"<br>}</pre> | no |
| cluster\_data | Required data relevant to joining an existing rke2 cluster, sourced from main rke2 module, do NOT modify | <pre>object({<br>    name       = string<br>    server_url = string<br>    cluster_sg = string<br>    token = object({<br>      bucket          = string<br>      bucket_arn      = string<br>      object          = string<br>      policy_document = string<br>    })<br>  })</pre> | n/a | yes |
| enable\_autoscaler | Toggle configure the nodepool for cluster autoscaler, this will ensure the appropriate IAM policies are present, you are still responsible for ensuring cluster autoscaler is installed | `bool` | `false` | no |
| enable\_ccm | Toggle enabling the cluster as aws aware, this will ensure the appropriate IAM policies are present | `bool` | `false` | no |
| extra\_block\_device\_mappings | Additional node pool block device mappings configuration | `list(map(string))` | `[]` | no |
| extra\_security\_group\_ids | List of additional security group IDs | `list(string)` | `[]` | no |
| iam\_instance\_profile | Node pool IAM Instance Profile, created if node specified | `string` | `""` | no |
| instance\_type | Node pool instance type | `string` | `"t3.medium"` | no |
| name | Nodepool name | `string` | n/a | yes |
| post\_userdata | Custom userdata to run immediately after rke2 node attempts to join cluster | `string` | `""` | no |
| pre\_userdata | Custom userdata to run immediately before rke2 node attempts to join cluster, after required rke2, dependencies are installed | `string` | `""` | no |
| rke2\_config | Node pool additional configuration passed as rke2 config file, see https://docs.rke2.io/install/install_options/agent_config for full list of options | `string` | `""` | no |
| rke2\_version | Version to use for RKE2 server nodepool | `string` | `"v1.18.10+rke2r1"` | no |
| ssh\_authorized\_keys | Node pool list of public keys to add as authorized ssh keys, not required | `list(string)` | `[]` | no |
| subnets | List of subnet IDs to create resources in | `list(string)` | n/a | yes |
| tags | Map of additional tags to add to all resources created | `map(string)` | `{}` | no |
| vpc\_id | VPC ID to create resources in | `string` | n/a | yes |
| wait_for_capacity_timeout | How long Terraform should wait for ASG instances to be healthy before timing out. | `string` | `"10m"` | no |
## Outputs

| Name | Description |
|------|-------------|
| iam\_instance\_profile | IAM instance profile attached to nodes in nodepool |
| iam\_role | IAM role of node pool |
| nodepool\_arn | n/a |
| nodepool\_id | n/a |
| nodepool\_name | n/a |
| security\_group | n/a |

