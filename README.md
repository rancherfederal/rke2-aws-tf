# rke2-aws-tf

`rke2` is lightweight, easy to use, and has minimal dependencies.  As such, there is a tremendous amount of flexibility for deployments that can be tailored to best suit you and your organization's needs.

This repository is inteded to clearly demonstrate one method of deploying `rke2` in a highly available, resilient, scalable, and simple method on AWS. It is by no means the only supported soluiton for running `rke2` on AWS.

We highly recommend you use the modules in this repository as stepping stones in solutions that meet the needs of your workflow and organization.  If you have suggestions or areas of improvements, we would [love to hear them](https://slack.rancher.io/)!

## Usage

This repository contains 2 terraform modules intended for user consumption:

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

#### Optional Policies

Optional policies have the option of being created by default, but are specified below if you are using a custom IAM role.

* Put `kubeconfig`: will upload the kubeconfig to the appropriate S3 bucket
    * [servers](./modules/statestore/main.tf#35)
* AWS Cloud Enabled Cluster: will configure `rke2` to self provision certain cloud resources, see [here]() for more info
    * [servers](./data.tf#58)
    * [agents](./modules/agent-nodepool/data.tf#2)
* AWS Cluster Autoscaler: will configure `rke2` to autoscale based off kubernetes resource requests
    * [agents](./modules/agent-nodepool/data.tf#27)