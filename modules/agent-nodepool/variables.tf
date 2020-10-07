variable "name" {
  description = "Nodepool name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to create nodepool in"
  type        = string
}

variable "subnets" {
  description = "List of subnet IDs to create nodepool in"
  type        = list(string)
}

variable "cluster_data" {
  description = "Required data for joining to an existing rke2 cluster, sourced from main rke2 module"

  type = object({
    name       = string
    server_dns = string
    cluster_sg = string
    token = object({
      address         = string
      policy_document = string
    })
  })
}

variable "tags" {
  description = "Map of tags to add to all resources created"
  type        = map(string)
  default     = {}
}

#
# Server Instance Variables
#
variable "ami" {
  description = "Nodepool ami"
  type        = string
}

variable "instance_type" {
  description = "Nodepool instance type"
  type        = string
  default     = "t3.medium"
}

variable "iam_instance_profile" {
  description = "Nodepool IAM Instance Profile, created if left empty"
  type        = string
  default     = ""
}

variable "block_device_mappings" {
  description = "Nodepool block device mapping configuration"
  type = object({
    size      = number
    encrypted = bool
  })

  default = {
    "size"      = 30
    "encrypted" = false
  }
}

variable "asg" {
  description = "Nodepool Auto Scaling Group capacities"
  type = object({
    min     = number
    max     = number
    desired = number
  })

  default = {
    min     = 1
    max     = 3
    desired = 2
  }
}

variable "spot" {
  default = false
  type    = bool
}

variable "ssh_authorized_keys" {
  description = "Nodepool list of public keys to add as authorized ssh keys"
  type        = list(string)
  default     = []
}

variable "extra_security_groups" {
  description = "Nodepool list of extra security groups to add"
  type        = list(string)
  default     = []
}

#
# Custom Userdata
#
variable "pre_userdata" {
  description = "Custom userdata to run immediately before rke2 agent attempts to join cluster, after required rke2, dependencies are installed"
  default     = ""
}

variable "post_userdata" {
  description = "Custom userdata to run immediately after rke2 agent attempts to join cluster"
  default     = ""
}

#
# RKE2 Variables
#
variable "rke2_version" {
  description = "Version to use for RKE2 agent nodepool"
  type        = string
  default     = "v1.18.9+rke2r1"
}

variable "rke2_config" {
  description = "Nodepool additional agent configuration passed as rke2 config file, see https://docs.rke2.io/install/install_options/agent_config for a full list of options"
  default     = ""
}
