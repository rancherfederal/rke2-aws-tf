# rke2-aws-tf

`rke2` is lightweight, easy to use, and has minimal dependencies.  As such, there is a tremendous amount of flexibility for deployments that can be tailored to best suit you and your organization's needs.

This repository is inteded to clearly demonstrate one method of deploying `rke2` in a highly available, resilient, scalable, and simple method on AWS. It is by no means the only supported solution for running `rke2` on AWS.

We highly recommend you use the modules in this repository as stepping stones in solutions that meet the needs of your workflow and organization.  If you have suggestions or areas of improvements, we would [love to hear them](https://slack.rancher.io/)!

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

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13 |

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| random | n/a |
| template | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ami | Server pool ami | `string` | n/a | yes |
| block\_device\_mappings | Server pool block device mapping configuration | `map(string)` | <pre>{<br>  "encrypted": false,<br>  "size": 30<br>}</pre> | no |
| cluster\_name | Name of the rkegov cluster to create | `string` | n/a | yes |
| controlplane\_access\_logs\_bucket | Set to bucket name to log requests to load balancer | `string` | `"disabled"` | no |
| controlplane\_allowed\_cidrs | Server pool security group allowed cidr ranges | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| controlplane\_enable\_cross\_zone\_load\_balancing | Toggle between controlplane cross zone load balancing | `bool` | `true` | no |
| controlplane\_internal | Toggle between public or private control plane load balancer | `bool` | `true` | no |
| download | Toggle best effort download of rke2 dependencies (rke2 and aws cli), if disabled, dependencies are assumed to exist in $PATH | `bool` | `true` | no |
| enable\_ccm | Toggle enabling the cluster as aws aware, this will ensure the appropriate IAM policies are present | `bool` | `false` | no |
| extra\_block\_device\_mappings | Additional server pool block device mappings configuration | `list(map(string))` | `[]` | no |
| iam\_instance\_profile | Server pool IAM Instance Profile, created if left blank (default behavior) | `string` | `""` | no |
| iam\_permissions\_boundary | If provided, the IAM role created for the servers will be created with this permissions boundary attached. | `string` | `null` | no |
| extra\_security\_group\_ids | List of additional security group IDs | `list(string)` | `[]` | no |
| instance\_type | Server pool instance type | `string` | `"t3a.medium"` | no |
| post\_userdata | Custom userdata to run immediately after rke2 node attempts to join cluster | `string` | `""` | no |
| pre\_userdata | Custom userdata to run immediately before rke2 node attempts to join cluster, after required rke2, dependencies are installed | `string` | `""` | no |
| rke2\_config | Server pool additional configuration passed as rke2 config file, see https://docs.rke2.io/install/install_options/server_config for full list of options | `string` | `""` | no |
| rke2\_version | Version to use for RKE2 server nodes | `string` | `"v1.18.12+rke2r2"` | no |
| servers | Number of servers to create | `number` | `1` | no |
| spot | Toggle spot requests for server pool | `bool` | `false` | no |
| ssh\_authorized\_keys | Server pool list of public keys to add as authorized ssh keys | `list(string)` | `[]` | no |
| subnets | List of subnet IDs to create resources in | `list(string)` | n/a | yes |
| tags | Map of tags to add to all resources created | `map(string)` | `{}` | no |
| unique\_suffix | Enables/disables generation of a unique suffix to cluster name | `bool` | `true` | yes |
| vpc\_id | VPC ID to create resources in | `string` | n/a | yes |
| wait_for_capacity_timeout | How long Terraform should wait for ASG instances to be healthy before timing out. | `string` | `"10m"` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster\_data | Map of cluster data required by agent pools for joining cluster, do not modify this |
| cluster\_name | Name of the rke2 cluster |
| cluster\_sg | Security group shared by cluster nodes, this is different than nodepool security groups |
| iam\_instance\_profile | IAM instance profile attached to server nodes |
| iam\_role | IAM role of server nodes |
| iam\_role\_arn | IAM role arn of server nodes |
| kubeconfig\_path | n/a |
| server\_nodepool\_arn | n/a |
| server\_nodepool\_id | n/a |
| server\_nodepool\_name | n/a |
| server\_sg | n/a |
| server\_url | n/a |
