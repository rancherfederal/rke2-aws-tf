# rke2-aws-tf

`rke2` is lightweight, easy to use, and has minimal dependencies.  As such, there is a tremendous amount of flexibility for deployments that can be tailored to best suit you and your organization's needs.

This repository is inteded to clearly demonstrate one method of deploying `rke2` in a highly available, resilient, scalable, and simple method on AWS. It is by no means the only supported solution for running `rke2` on AWS.

We highly recommend you use the modules in this repository as stepping stones in solutions that meet the needs of your workflow and organization.  If you have suggestions or areas of improvements, we would [love to hear them](https://slack.rancher.io/)!

## Non-Backwards compatible changes

Changes have been introduced as of March 2023 that are not compatible with user-defined environments.  Please make note of and test the following changes before deploying into your environments:

-rke2 user is no longer being installed by default for both servers and agents.
-cloud-init runcmd scripts have been re-numbered as follows:
  - 00_pre.sh
  - 10_download.sh
  - 20_rke2.sh
  - 99_post.sh

  If you are using additional cloud-init scripts, ensure that their numbering will run in the order you expect.
-When setting the 'asg' variable, you now must also set the 'termination_policy' value.

## Usage

This repository contains 2 terraform modules intended for user consumption:

```hcl
# Provision rke2 server(s) and controlplane loadbalancer
module "rke2" {
  source  = "git::https://github.com/rancherfederal/rke2-aws-tf.git"
  name    = "quickstart"
  vpc_id  = "vpc-###"
  subnets = ["subnet-###"]
  ami     = "ami-###"
}

# Provision Auto Scaling Group of agents to auto-join cluster
module "rke2_agents" {
  source  = "git::https://github.com/rancherfederal/rke2-aws-tf.git//modules/agent-nodepool"
  name    = "generic"
  vpc_id  = "vpc-###"
  subnets = ["subnet-###"]
  ami     = "ami-###"

  # Required input sourced from parent rke2 module, contains configuration that agents use to join existing cluster
  cluster_data = module.rke2.cluster_data
}
```

For more complete options, fully functioning examples are provided in the `examples/` folder to meet the various use cases of `rke2` clusters on AWS, ranging from:

* `examples/quickstart`: bare minimum rke2 server/agent cluster, start here!
* `examples/cloud-enabled`: aws cloud aware rke2 cluster

## Overview

The deployment model of this repository is designed to feel very similar to the major cloud providers kubernetes distributions.

It revolves around provisioning the following:

* Nodepools: Self-bootstrapping and auto-joining _groups_ of EC2 instances
* AWS NLB: Controlplane static address

This iac leverages the ease of use of `rke2` to provide a simple sshless bootstrapping process for sets of cluster nodes, known as `nodepools`.  Both the servers and agents within the cluster are simply one or more Auto Scaling Groups (ASG) with the necessary [minimal userdata]() required for either creating or joining an `rke2` cluster.

Upon ASG boot, every node will:

1. Install the `rke2` [self-extracting binary](https://docs.rke2.io/install/requirements/) from [https://get.rke2.io](https://get.rke2.io)
2. Fetch the `rke2` cluster token from a secure secrets store (s3)
3. Initialize or join an `rke2` cluster

The most basic deployment involves a server `nodepool`.  However, most deployments will see a server `nodepool` with one or more logical groups of `agent` nodepools.  These are typically separated based of node labels, workload functions, instance types, or any physical/logical separation of nodes.

## Terraform Modules

This repository contains 2 primary modules that users are expected to consume:

__`rke2`__:

The primary `rke2` cluster component.  Defining this is mandatory, and will provision a control plane load balancer (AWS NLB) and a server nodepool.

__`agent-nodepool`__

Optional (but recommended) cluster component to create agent nodepools that will auto-join the cluster created using the `rke2` module.  This is the primary method for defining nodes in which cluster workloads will run.

### Secrets

Since it is [bad practice]() to store sensitive information in userdata, s3 is used as a secure secrets store that is commonly available in all instantiations of AWS is used for storing and fetching the `token`.  Provisioned nodes will fetch the `token` from the appropriate secrets store via the `awscli` before attempting to join a cluster.

### IAM Policies

This module has a mininmum dependency on being able to fetch the cluster join token from an S3 bucket.  By default, the bucket, token, roles, and minimum policies will be created for you.  For restricted environments unable to create IAM Roles or Policies, you can specify an existing IAM Role that the instances will assume instead.  Note that when going this route, you must be sure the IAM role specified has the minimum required policies to fetch the cluster token from S3.  The required and optional policies are defined below:

#### Required Policies

Required policies are created by default, but are specified below if you are using a custom IAM role.

##### Get Token

Servers and agents need to be able to fetch the cluster join token

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:GetObject",
            "Resource": "arn:<aws-region>:s3:<aws-region>:<aws-account>:<bucket>:<object>"
        }
    ]
}
```

**Note:** The S3 bucket will be dynamically created during cluster creation, in order to pre create an iam policy that points to this bucket, the use of wildcards is recommended.
For example: `s3:::us-gov-west-1:${var.cluster_name}-*`

##### Get Autoscaling Instances

Servers need to be able to query instances within their autoscaling group for "leader election".

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": "*",
            "Action": [
              "autoscaling:DescribeAutoScalingGroups",
              "autoscaling:DescribeAutoScalingInstances"
            ]
        }
    ]
}
```

#### Optional Policies

Optional policies have the option of being created by default, but are specified below if you are using a custom IAM role.

* Put `kubeconfig`: will upload the kubeconfig to the appropriate S3 bucket
    * [servers](./modules/statestore/main.tf#35)
* AWS Cloud Enabled Cluster: will configure `rke2` to self provision certain cloud resources, see [here]() for more info
    * [servers](./data.tf#58)
    * [agents](./modules/agent-nodepool/data.tf#2)
* AWS Cluster Autoscaler: will configure `rke2` to autoscale based off kubernetes resource requests
    * [agents](./modules/agent-nodepool/data.tf#27)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.6, <= 5.22 |
| <a name="requirement_cloudinit"></a> [cloudinit](#requirement\_cloudinit) | >= 2 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.6, <= 5.22 |
| <a name="provider_cloudinit"></a> [cloudinit](#provider\_cloudinit) | >= 2 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cp_lb"></a> [cp\_lb](#module\_cp\_lb) | ./modules/nlb | n/a |
| <a name="module_iam"></a> [iam](#module\_iam) | ./modules/policies | n/a |
| <a name="module_init"></a> [init](#module\_init) | ./modules/userdata | n/a |
| <a name="module_servers"></a> [servers](#module\_servers) | ./modules/nodepool | n/a |
| <a name="module_statestore"></a> [statestore](#module\_statestore) | ./modules/statestore | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role_policy.aws_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.aws_ccm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.aws_required](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.get_token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.put_kubeconfig](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_security_group.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.cluster_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.cluster_shared](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.server_cp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.server_cp_supervisor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [random_password.token](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.uid](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_iam_policy_document.aws_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.aws_ccm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.aws_required](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_role.provided](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [cloudinit_config.this](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami"></a> [ami](#input\_ami) | Server pool ami | `string` | n/a | yes |
| <a name="input_associate_public_ip_address"></a> [associate\_public\_ip\_address](#input\_associate\_public\_ip\_address) | n/a | `bool` | `null` | no |
| <a name="input_awscli_url"></a> [awscli\_url](#input\_awscli\_url) | URL for awscli zip file | `string` | `"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"` | no |
| <a name="input_block_device_mappings"></a> [block\_device\_mappings](#input\_block\_device\_mappings) | Server pool block device mapping configuration | `map(string)` | <pre>{<br>  "encrypted": false,<br>  "size": 30<br>}</pre> | no |
| <a name="input_ccm_external"></a> [ccm\_external](#input\_ccm\_external) | Set kubelet arg 'cloud-provider-name' value to 'external'.  Requires manual install of CCM. | `bool` | `false` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the rkegov cluster to create | `string` | n/a | yes |
| <a name="input_controlplane_access_logs_bucket"></a> [controlplane\_access\_logs\_bucket](#input\_controlplane\_access\_logs\_bucket) | Bucket name for logging requests to control plane load balancer | `string` | `"disabled"` | no |
| <a name="input_controlplane_allowed_cidrs"></a> [controlplane\_allowed\_cidrs](#input\_controlplane\_allowed\_cidrs) | Server pool security group allowed cidr ranges | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_controlplane_enable_cross_zone_load_balancing"></a> [controlplane\_enable\_cross\_zone\_load\_balancing](#input\_controlplane\_enable\_cross\_zone\_load\_balancing) | Toggle between controlplane cross zone load balancing | `bool` | `true` | no |
| <a name="input_controlplane_internal"></a> [controlplane\_internal](#input\_controlplane\_internal) | Toggle between public or private control plane load balancer | `bool` | `true` | no |
| <a name="input_create_acl"></a> [create\_acl](#input\_create\_acl) | Toggle creation of ACL for statestore bucket | `bool` | `true` | no |
| <a name="input_download"></a> [download](#input\_download) | Toggle best effort download of rke2 dependencies (rke2 and aws cli), if disabled, dependencies are assumed to exist in $PATH | `bool` | `true` | no |
| <a name="input_enable_autoscaler"></a> [enable\_autoscaler](#input\_enable\_autoscaler) | Toggle enabling policies required for cluster autoscaler to work | `bool` | `false` | no |
| <a name="input_enable_ccm"></a> [enable\_ccm](#input\_enable\_ccm) | Toggle enabling the cluster as aws aware, this will ensure the appropriate IAM policies are present | `bool` | `false` | no |
| <a name="input_extra_block_device_mappings"></a> [extra\_block\_device\_mappings](#input\_extra\_block\_device\_mappings) | Used to specify additional block device mapping configurations | `list(map(string))` | `[]` | no |
| <a name="input_extra_cloud_config_config"></a> [extra\_cloud\_config\_config](#input\_extra\_cloud\_config\_config) | extra config to append to cloud-config | `string` | `""` | no |
| <a name="input_extra_security_group_ids"></a> [extra\_security\_group\_ids](#input\_extra\_security\_group\_ids) | List of additional security group IDs | `list(string)` | `[]` | no |
| <a name="input_iam_instance_profile"></a> [iam\_instance\_profile](#input\_iam\_instance\_profile) | Server pool IAM Instance Profile, created if left blank (default behavior) | `string` | `""` | no |
| <a name="input_iam_permissions_boundary"></a> [iam\_permissions\_boundary](#input\_iam\_permissions\_boundary) | If provided, the IAM role created for the servers will be created with this permissions boundary attached. | `string` | `null` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Server pool instance type | `string` | `"t3a.medium"` | no |
| <a name="input_lb_subnets"></a> [lb\_subnets](#input\_lb\_subnets) | List of subnet IDs to create load balancer in | `list(string)` | `null` | no |
| <a name="input_metadata_options"></a> [metadata\_options](#input\_metadata\_options) | Instance Metadata Options | `map(any)` | <pre>{<br>  "http_endpoint": "enabled",<br>  "http_put_response_hop_limit": 2,<br>  "http_tokens": "required",<br>  "instance_metadata_tags": "disabled"<br>}</pre> | no |
| <a name="input_post_userdata"></a> [post\_userdata](#input\_post\_userdata) | Custom userdata to run immediately after rke2 node attempts to join cluster | `string` | `""` | no |
| <a name="input_pre_userdata"></a> [pre\_userdata](#input\_pre\_userdata) | Custom userdata to run immediately before rke2 node attempts to join cluster, after required rke2, dependencies are installed | `string` | `""` | no |
| <a name="input_rke2_channel"></a> [rke2\_channel](#input\_rke2\_channel) | Channel to use for RKE2 server nodepool | `string` | `null` | no |
| <a name="input_rke2_config"></a> [rke2\_config](#input\_rke2\_config) | Server pool additional configuration passed as rke2 config file, see https://docs.rke2.io/install/install_options/server_config for full list of options | `string` | `""` | no |
| <a name="input_rke2_install_script_url"></a> [rke2\_install\_script\_url](#input\_rke2\_install\_script\_url) | URL for RKE2 install script | `string` | `"https://get.rke2.io"` | no |
| <a name="input_rke2_start"></a> [rke2\_start](#input\_rke2\_start) | Start/Stop value for the rke2-server/agent service.  This will prevent the service from starting until the next reboot. True=start, False= don't start. | `bool` | `true` | no |
| <a name="input_rke2_version"></a> [rke2\_version](#input\_rke2\_version) | Version to use for RKE2 server nodepool | `string` | `null` | no |
| <a name="input_servers"></a> [servers](#input\_servers) | Number of servers to create | `number` | `3` | no |
| <a name="input_spot"></a> [spot](#input\_spot) | Toggle spot requests for server pool | `bool` | `false` | no |
| <a name="input_ssh_authorized_keys"></a> [ssh\_authorized\_keys](#input\_ssh\_authorized\_keys) | Server pool list of public keys to add as authorized ssh keys | `list(string)` | `[]` | no |
| <a name="input_statestore_attach_deny_insecure_transport_policy"></a> [statestore\_attach\_deny\_insecure\_transport\_policy](#input\_statestore\_attach\_deny\_insecure\_transport\_policy) | Toggle for enabling s3 policy to reject non-SSL requests | `bool` | `true` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | List of subnet IDs to create nodes in | `list(string)` | n/a | yes |
| <a name="input_suspended_processes"></a> [suspended\_processes](#input\_suspended\_processes) | List of processes to suspend in the autoscaling service | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to add to all resources created | `map(string)` | `{}` | no |
| <a name="input_termination_policies"></a> [termination\_policies](#input\_termination\_policies) | List of policies to decide how the instances in the Auto Scaling Group should be terminated | `list(string)` | <pre>[<br>  "Default"<br>]</pre> | no |
| <a name="input_unique_suffix"></a> [unique\_suffix](#input\_unique\_suffix) | Enables/disables generation of a unique suffix to cluster name | `bool` | `true` | no |
| <a name="input_unzip_rpm_url"></a> [unzip\_rpm\_url](#input\_unzip\_rpm\_url) | URL path to unzip rpm | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID to create resources in | `string` | n/a | yes |
| <a name="input_wait_for_capacity_timeout"></a> [wait\_for\_capacity\_timeout](#input\_wait\_for\_capacity\_timeout) | How long Terraform should wait for ASG instances to be healthy before timing out. | `string` | `"10m"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_data"></a> [cluster\_data](#output\_cluster\_data) | Map of cluster data required by agent pools for joining cluster, do not modify this |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the rke2 cluster |
| <a name="output_cluster_sg"></a> [cluster\_sg](#output\_cluster\_sg) | Security group shared by cluster nodes, this is different than nodepool security groups |
| <a name="output_iam_instance_profile"></a> [iam\_instance\_profile](#output\_iam\_instance\_profile) | IAM instance profile attached to server nodes |
| <a name="output_iam_role"></a> [iam\_role](#output\_iam\_role) | IAM role of server nodes |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | IAM role arn of server nodes |
| <a name="output_kubeconfig_path"></a> [kubeconfig\_path](#output\_kubeconfig\_path) | n/a |
| <a name="output_server_nodepool_arn"></a> [server\_nodepool\_arn](#output\_server\_nodepool\_arn) | n/a |
| <a name="output_server_nodepool_id"></a> [server\_nodepool\_id](#output\_server\_nodepool\_id) | n/a |
| <a name="output_server_nodepool_name"></a> [server\_nodepool\_name](#output\_server\_nodepool\_name) | n/a |
| <a name="output_server_sg"></a> [server\_sg](#output\_server\_sg) | n/a |
| <a name="output_server_url"></a> [server\_url](#output\_server\_url) | n/a |
<!-- END_TF_DOCS -->
