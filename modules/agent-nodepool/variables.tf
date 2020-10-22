variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "instance_type" {
  default = "t3.medium"
}

variable "ami" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

#
# Nodepool Variables
#
variable "iam_instance_profile" {
  type    = string
  default = ""
}

variable "ssh_authorized_keys" {
  type    = list(string)
  default = []
}

variable "block_device_mappings" {
  type = map(string)

  default = {
    "size" = 30
    type   = "gp2"
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
    max     = 10
    desired = 1
  }
}

#
# RKE2 Variables
#
variable "cluster_data" {
  description = "Required data relevant to joining an existing rke2 cluster, sourced from main rke2 module"

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
  default     = "v1.18.9+rke2r1"
}

variable "rke2_config" {
  default = ""
}

variable "enable_ccm" {
  description = "Toggle enabling the cluster as aws aware, this will ensure the appropriate IAM policies are present"
  type        = bool
  default     = false
}
