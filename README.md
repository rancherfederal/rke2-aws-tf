# rke2-aws-tf

Sample terraform modules for creating [rke2](https://github.com/rancher/rke2) clusters on AWS.

`rke2` is lightweight, easy to use, and has minimal dependencies.  As such, there is a tremendous amount of flexibility for deployments that can be tailored to best suit you and your organization's needs.

This repository is inteded to clearly demonstrate one method of deploying `rke2` in a highly available, resilient, scalable, and simple method on AWS. It is by no means the only supported, or official method for running `rke2` on AWS.

We highly recommend you use this repository as a stepping stone for solutions that meet the needs of your workflow and organization.  If you have suggestions or areas of improvements, we would [love to hear them](https://slack.rancher.io/)!

## Usage

```hcl
# Provision rke2 server(s) and controlplane loadbalancer
module "rke2" {
  source  = "git::https://github.com/rancherfederal/rke2-aws-tf.git"
  name    = "rke2-quickstart"
  vpc_id  = "vpc-###"
  subnets = ["subnet-###"]
  ami     = "ami-###"
}

# Provision Auto Scaling Group of agents to auto-join cluster
module "rke2_agents" {
  source  = "git::https://github.com/rancherfederal/rke2-aws-tf.git/modules/agent-nodepool"
  name    = "agents"
  vpc_id  = "vpc-###"
  subnets = ["subnet-###"]
  ami     = "ami-###"

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
* AWS ELB: Controlplane static address

This iac leverages the ease of use of `rke2` to provide a simple pull based bootstrapping process for sets of cluster nodes, known as `nodepools`.  Both the servers and agents within the cluster are simply one or more Auto Scaling Groups (ASG) with the necessary [minimal userdata]() required for either creating or joining an `rke2` cluster.

Upon ASG boot, every node will:

1. Install the `rke2` [self-extracting binary](https://docs.rke2.io/install/requirements/) from [https://get.rke2.io](https://get.rke2.io)
2. Fetch the `rke2` cluster token from a secure secrets store (secretsmanager or s3)
3. Initialize or join an `rke2` cluster

The most basic deployment involves a single server `nodepool`.  However, most deployments will see a single server `nodepool` with one or more logical groups of `agent` nodepools.  This can be separated based of ndoe labels, workload functions, instance types, or any physical/logical separation of nodes.

## Terraform Components

This repository contains 2 primary modules that users are expected to consume:

__`rke2`__:

The primary `rke2` cluster component.  Defining this is mandatary, and will provision a control plane load balancer (AWS NLB) and server nodepools.

__`agent-nodepool`__

Optional (but recommended) cluster component to create agent nodepools that will auto-join the cluster created using the `rke2` module.  This is the primary method for defining nodes in which cluster workloads will run.

### Secrets

Although `nodepools` are self bootstrapping, there is secure cluster information that needs to be stored outside of the cluster to protect which nodes are allowed to join the cluster.  In the case of `rke2`, this is the `token`.

Since it is [bad practice]() to store sensitive information in userdata, a secure secrets store is used for storing and fetching the `token`.  Provisioned nodes will fetch the `token` from the appropriate secrets store via the `awscli` before attempting to join a cluster.

### IAM Policies

Since the node `token` is stored and fetched securely, there is an inherent dependency on secretsmanager or s3, but also the ability for nodes to interact with those services.  By default, this module will create the _bare minimum_ policies for interfacing with secretsmanager or s3.  These policy documents are listed below.

secretsmanager:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "arn:<aws-region>:secretsmanager:<aws-region>:<aws-account>:secret:<rke2-cluster-secret-name>"
        }
    ]
}
```

s3:

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

In addition to the __required__ policies above, suggested policies will also be created that are the bare mininmum required to support an aws cloud enabled cluster.  You can view these policies in the upstream AWS Cloud Controller Manager repository [here](https://github.com/kubernetes/cloud-provider-aws#iam-policy).

All of the policies defined above will be attached to a created role assigned to their respective `server` or `agent` nodepool.  

If an `iam_instance_profile` is provided to either the `rke2` or `agent-nodepool` module, none of the IAM instances will be created, and it will be up to the user to know that the assigned policy meets the mininum required permissions for fetching the token.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13, < 0.14 |

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| random | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ami | Server pool ami | `string` | n/a | yes |
| asg | Server pool Auto Scaling Group capacities | <pre>object({<br>    min     = number<br>    max     = number<br>    desired = number<br>  })</pre> | <pre>{<br>  "desired": 1,<br>  "max": 9,<br>  "min": 1<br>}</pre> | no |
| block\_device\_mappings | Server pool block device mapping configuration | <pre>object({<br>    size      = number<br>    encrypted = bool<br>  })</pre> | <pre>{<br>  "encrypted": false,<br>  "size": 30<br>}</pre> | no |
| controlplane\_allowed\_cidrs | Server pool security group allowed cidr ranges | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| iam\_instance\_profile | Server pool IAM Instance Profile, created if left blank | `string` | `""` | no |
| instance\_type | Server pool instance type | `string` | `"t3a.medium"` | no |
| name | Name of the rkegov cluster to create | `string` | n/a | yes |
| post\_userdata | Custom userdata to run immediately after rke2 node attempts to join cluster | `string` | `""` | no |
| pre\_userdata | Custom userdata to run immediately before rke2 node attempts to join cluster, after required rke2, dependencies are installed | `string` | `""` | no |
| rke2\_config | Server pool additional configuration passed as rke2 config file, see https://docs.rke2.io/install/install_options/server_config for full list of options | `string` | `""` | no |
| ssh\_authorized\_keys | Server pool list of public keys to add as authorized ssh keys | `list(string)` | `[]` | no |
| subnets | List of subnet IDs to create resources in | `list(string)` | n/a | yes |
| tags | Map of tags to add to all resources created | `map(string)` | `{}` | no |
| token\_store | Token store to use, can be either `secretmanager` or `s3` | `string` | `"secretsmanager"` | no |
| vpc\_id | VPC ID to create resources in | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cluster\_data | Map of cluster data required by agent pools for joining cluster, do not modify this |
| cluster\_name | Name of the rke2 cluster |

