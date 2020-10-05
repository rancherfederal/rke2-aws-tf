# AWS Cloud Enabled RKE2

This example demonstrates configuring `rke2` with the in tree AWS Cloud Controller Manager (CCM).

The `rke2` configuration file option is used to configure `cloud-provider-name: aws`.

Note that resource tagging is extremely important when enabling the AWS CCM, as it is how the controller identifies resources for things such as autoprovisioning load balancers.

Regardless of the aws provider being explicitly declared, all resources created by `rke2-aws-tf` are tagged appropriately. However, there are resources not owned by `rke2-aws-tf` proper, such as VPC's and Subnets.  This example explicitly declares VPCs and Subnets with the appropriate tags so you can get a feel for all the required resources in your own environment.
