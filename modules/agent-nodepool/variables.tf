variable "name" {
  type = string
}

variable "cluster" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}

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
variable "cluster_security_group" {
  type = string
}

variable "extra_security_groups" {
  type    = list(string)
  default = []
}

#
#
#
variable "server_url" {
  type = string
}

variable "token" {
  type = string
}

variable "node_labels" {
  type    = list(string)
  default = []
}

variable "node_taints" {
  type    = list(string)
  default = []
}