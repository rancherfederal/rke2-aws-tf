# public-lb

Demonstrates a cluster with nodes spread across three availability zones in private subnets with a load balancer for the API server in the same availability zones but public subnets. It is mandatory in AWS to put an Internet-facing load balancer in public subnets or it will not be routable from the Internet, in spite of having public IPs.

## Connecting to cluster nodes

Running the following as-is requires `jq` and `sshuttle`, but it is also possible to do this the hard way if you're familiar with ssh tunneling.

Get the IP address of the bastion, the generated cluster name, and the VPC CIDR range:

```sh
BASTION_IP=$(terraform output -raw bastion_ip)
CLUSTER_NAME=$(terraform output -json cluster_data | jq '.cluster_name' | tr -d '"')
VPC_CIDR=$(terraform output -raw vpc_cidr)
```

Establish an ssh tunnel using `sshuttle`:

```sh
sshuttle -r ec2-user@$BASTION_IP $VPC_CIDR --ssh-cmd "ssh -i $CLUSTER_NAME.pem"
```

In a second terminal, get the private IP of the first cluster node. We're just picking one here to demonstrate, but of course you can choose any other or all at once if you want to use `tmux` to establish simulataneous connections from the same terminal. The following assume you're still in the same directory Terraform was run from.

```sh
NODE0_IP=$(aws ec2 describe-instances \
  --filter "Name=tag:aws:autoscaling:groupName,Values=public-lb*" \
  --query "Reservations[*].Instances[0].PrivateIpAddress" \
  --output text)
ssh -i $CLUSTER_NAME.pem ec2-user@$NODE0_IP
```
