variable "name" {
  type        = string
  description = "Name of the rkegov cluster to create"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID to create resources in"
}

variable "subnets" {
  type        = list(string)
  description = "List of subnet IDs to create resources in"
}

variable "token_store" {
  type    = string
  default = "secretsmanager"
}

variable "tags" {
  default = {}
  type    = map(string)
}

# instance variables
variable "instance_type" {
  type    = string
  default = "t3a.medium"
}

variable "ami" {
  type = string
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
    max     = 9
    desired = 1
  }
}

variable "controlplane_allowed_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "ssh_authorized_keys" {
  type    = list(string)
  default = []
}

#
# Custom Userdata
#
variable "pre_userdata" {
  description = "Custom userdata to run immediately before rke2 node attempts to join cluster, after required rke2, dependencies are installed"
  default     = ""
}

variable "post_userdata" {
  description = "Custom userdata to run immediately after rke2 node attempts to join cluster"
  default     = ""
}

# rkegov variables
variable "rke2_config" {
  default     = ""
  description = "User defined extra input to rke2.yaml"
}
