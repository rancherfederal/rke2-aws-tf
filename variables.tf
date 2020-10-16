variable "cluster_name" {
  description = "Name of the rkegov cluster to create"
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

variable "token_store" {
  description = "Token store to use, can be either `secretmanager` or `s3`"
  type        = string
  default     = "secretsmanager"
}

variable "tags" {
  description = "Map of tags to add to all resources created"
  default     = {}
  type        = map(string)
}

#
# Server pool variables
#
variable "instance_type" {
  type        = string
  default     = "t3a.medium"
  description = "Server pool instance type"
}

variable "ami" {
  description = "Server pool ami"
  type        = string
}

variable "iam_instance_profile" {
  description = "Server pool IAM Instance Profile, created if left blank"
  type        = string
  default     = ""
}

variable "block_device_mappings" {
  description = "Server pool block device mapping configuration"
  type = object({
    size      = number
    encrypted = bool
  })

  default = {
    "size"      = 30
    "encrypted" = false
  }
}

variable "servers" {
  description = "Number of servers to create"
  type        = number
  default     = 1
}

variable "ssh_authorized_keys" {
  description = "Server pool list of public keys to add as authorized ssh keys"
  type        = list(string)
  default     = []
}

#
# Controlplane Variables
#
variable "controlplane_enable_cross_zone_load_balancing" {
  description = "Toggle between controlplane cross zone load balancing"
  default     = true
  type        = bool
}

variable "controlplane_internal" {
  description = "Toggle between public or private control plane load balancer"
  default     = true
  type        = bool
}

variable "controlplane_allowed_cidrs" {
  description = "Server pool security group allowed cidr ranges"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}


#
# RKE2 Variables
#
variable "rke2_version" {
  description = "Version to use for RKE2 server nodes"
  type        = string
  default     = "v1.18.10+rke2r1"
}

variable "rke2_config" {
  description = "Server pool additional configuration passed as rke2 config file, see https://docs.rke2.io/install/install_options/server_config for full list of options"
  type        = string
  default     = ""
}

variable "pre_userdata" {
  description = "Custom userdata to run immediately before rke2 node attempts to join cluster, after required rke2, dependencies are installed"
  type        = string
  default     = ""
}

variable "post_userdata" {
  description = "Custom userdata to run immediately after rke2 node attempts to join cluster"
  type        = string
  default     = ""
}

