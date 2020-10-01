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
    max     = 3
    desired = 2
  }
}

variable "server_count" {
  type    = number
  default = 3
}

variable "ssh_authorized_keys" {
  type    = list(string)
  default = []
}

# rkegov variables
//variable "rke2_version" {
//  default = "v1.18.9-beta23+rke2"
//  description = "RKE2 version to install"
//}
//
//variable "rke2_method" {
//  default = "tar"
//  description = "RKE2 installation method, defaults to tar regardless of system"
//}

variable "rke2_config" {
  default     = ""
  description = "User defined extra input to rke2.yaml"
}
