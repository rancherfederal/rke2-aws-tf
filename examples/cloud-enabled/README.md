# AWS Cloud Enabled RKE2

This example demonstrates configuring `rke2` with the Kubernetes `cloud-provider-aws`.

The in-tree provider is now deprecated and removed completely as of Kubernetes v1.27. The flag to the kubelet to provide a cloud-provider name at all has also been deprecated since v1.24 and is subject to removal at any time. Thus, we will show how to install the out-of-tree provider and autoscaler instead.

Now, however, that until [cloud-provider-aws/746](https://github.com/kubernetes/cloud-provider-aws/issues/746) is fixed, we need to continue passing `cloud-provider-name: external` to `rke2`, which will still work as of Kubernetes v1.28.

Note that resource tagging is extremely important when enabling the AWS CCM, as it is how the controller identifies resources for things such as autoprovisioning load balancers.

Regardless of the aws provider being explicitly declared, all resources created by `rke2-aws-tf` are tagged appropriately. However, there are resources not owned by `rke2-aws-tf` proper, such as VPC's and Subnets.  This example explicitly declares VPCs and Subnets with the appropriate tags so you can get a feel for all the required resources in your own environment.

Also see [kubernetes/website/42770](https://github.com/kubernetes/website/issues/42770). We need to tell the Kubernetes Controller Manager here not to try and configure node CIDRs and cloud routes because Calico does not need these. All of the supported CNIs for `rke2` should be using vxlan or something equivalent, not setting routes in the VPC route table directly.

## `cloud-provider-aws`

```sh
helm repo add aws-cloud-controller-manager https://kubernetes.github.io/cloud-provider-aws
helm repo update
helm install aws-cloud-controller-manager aws-cloud-controller-manager/aws-cloud-controller-manager \
  --namespace kube-system \
  --set-json 'args=["--v=2", "--cloud-provider=aws", "--allocate-node-cidrs=false", "--configure-cloud-routes=false"]' \
  --set-string 'nodeSelector.node-role\.kubernetes\.io/control-plane=true'
```

## `cluster-autoscaler`

Match region to your actual region, but it is `us-gov-west-1` in this example.

```sh
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update
helm install autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=cloud-enabled-zjl \
  --set awsRegion=us-gov-west-1
```
