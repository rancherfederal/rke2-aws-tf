variable "name" {
  description = "Nodepool name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to create resources in"
  type        = string
}

variable "subnets" {
  description = "List of subnet IDs to create resources in"
  type        = list(string)
}

variable "instance_type" {
  description = "Node pool instance type"
  default     = "t3.medium"
}

variable "ami" {
  description = "Node pool ami"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Map of additional tags to add to all resources created"
  type        = map(string)
  default     = {}
}

#
# Nodepool Variables
#
variable "iam_instance_profile" {
  description = "Node pool IAM Instance Profile, created if node specified"
  type        = string
  default     = ""
}

variable "ssh_authorized_keys" {
  description = "Node pool list of public keys to add as authorized ssh keys, not required"
  type        = list(string)
  default     = []
}

variable "block_device_mappings" {
  description = "Node pool block device mapping configuration"
  type        = map(string)

  default = {
    "size" = 30
    type   = "gp2"
  }
}

variable "asg" {
  description = "Node pool AutoScalingGroup scaling definition"
  type = object({
    min     = number
    max     = number
    desired = number
  })

  default = {
    min     = 1
    max     = 10
    desired = 1
  }
}

variable "spot" {
  description = "Toggle spot requests for node pool"
  type        = bool
  default     = false
}

#
# RKE2 Variables
#
variable "cluster_data" {
  description = "Required data relevant to joining an existing rke2 cluster, sourced from main rke2 module, do NOT modify"

  type = object({
    name       = string
    server_url = string
    cluster_sg = string
    token = object({
      bucket          = string
      bucket_arn      = string
      object          = string
      policy_document = string
    })
  })
}

variable "rke2_version" {
  description = "Version to use for RKE2 server nodepool"
  type        = string
  default     = "v1.18.10+rke2r1"
}

variable "rke2_config" {
  description = "Node pool additional configuration passed as rke2 config file, see https://docs.rke2.io/install/install_options/agent_config for full list of options"
  default     = ""
}

variable "enable_ccm" {
  description = "Toggle enabling the cluster as aws aware, this will ensure the appropriate IAM policies are present"
  type        = bool
  default     = false
}

variable "enable_autoscaler" {
  description = "Toggle configure the nodepool for cluster autoscaler, this will ensure the appropriate IAM policies are present, you are still responsible for ensuring cluster autoscaler is installed"
  type        = bool
  default     = false
}
