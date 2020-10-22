variable "name" {
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

variable "agent" {
  description = "Toggle server or agent init, defaults to agent"
  type        = bool
  default     = true
}

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

variable "userdata" {
  type    = string
  default = ""
}

variable "instance_type" {
  default = "t3.medium"
}

variable "ami" {
  type    = string
  default = ""
}

variable "iam_instance_profile" {
  type    = string
  default = ""
}

variable "health_check_type" {
  type    = string
  default = "EC2"
}

variable "target_group_arns" {
  type    = list(string)
  default = []
}

variable "vpc_security_group_ids" {
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

variable "min_elb_capacity" {
  type    = number
  default = null
}

#
# RKE2 Variables
#
variable "rke2_version" {
  description = "Version to use for RKE2 server nodepool"
  type        = string
  default     = "v1.18.9+rke2r1"
}

variable "rke2_config" {
  default = ""
}
