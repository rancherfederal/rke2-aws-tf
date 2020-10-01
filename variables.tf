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
variable "node_labels" {
  type    = list(string)
  default = []
}

variable "node_taints" {
  type    = list(string)
  default = []
}

variable "write_kubeconfig_mode" {
  default     = "0644"
  description = "Write kubeconfig with this mode"
}

variable "kube_apiserver_args" {
  type    = list(string)
  default = []
}

variable "kube_scheduler_args" {
  type    = list(string)
  default = []
}

variable "kube_controller_manager_args" {
  type    = list(string)
  default = []
}