# examples

[cloud-enabled](./cloud-enabled/): Shows a cluster with nodepools having the appropriate IAM policies and tags to enable using `cloud-provider-aws`, `cluster-autoscaler`, and `ebs-csi-driver` with KMS volume encryption.

[public-lb](./public-lb/): Shows a cluster with nodepools in private VPC subnets with the API server fronted by an Internet-facing load balancer.

[quickstart](./quickstart/): Minimal deployment with automated kubeconfig fetching and ssh to cluster nodes allowed from anywhere on the Internet.

## AMI queries

The Terraform data resource `aws_ami` constructs an API query such that the block of hcl below:

```hcl
data "aws_ami" "rhel9" {
  most_recent = true
  owners      = ["219670896067"]

  filter {
    name   = "name"
    values = ["RHEL-9*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
```

Is equivalent to the AWS CLI call:

```sh
aws ec2 describe-images \
  --owners 219670896067 \
  --filter "Name=name,Values=RHEL-9*" \
  --filter "Name=architecture,Values=x86_64" \
  --query "reverse(sort_by(Images, &CreationDate))[0]"
```

## Interacting with your cluster

The `cloud-init` user-data scripts provided with this module always upload the default admin kubeconfig from `/etc/rancher/rke2/rke2.yaml` to the S3 statestore bucket upon successful startup of the `rke2-server` service on the first cluster node, editing the localhost server URL to use the DNS name of the load balancer. Some examples demonstrate a Terraform null resource to download this. To download using AWS CLI and then use it:

```sh
aws s3 cp s3://public-lb-gkw-rke2/rke2.yaml .
chmod 0600 rke2.yaml
export KUBECONFIG="$(pwd)/rke2.yaml"
```
