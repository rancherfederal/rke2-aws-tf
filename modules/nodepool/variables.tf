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