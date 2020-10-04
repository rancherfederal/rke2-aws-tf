variable "name" {
  description = "RKE2 cluster name"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "cluster_data" {
  description = "Required data relevant to joining an existing rke2 cluster, sourced from main rke2 module"

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
  type    = map(string)
  default = {}
}

#
# Server Instance Variables
#
variable "ami" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "iam_instance_profile" {
  type    = string
  default = ""
}

variable "block_device_mappings" {
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
  type    = list(string)
  default = []
}

#
#
#
variable "extra_security_groups" {
  type    = list(string)
  default = []
}

#
# RKE2 Variables
#
variable "rke2_config" {
  default = ""
}
