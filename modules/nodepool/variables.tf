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

variable "wait_for_capacity_timeout" {
  description = "How long Terraform should wait for ASG instances to be healthy before timing out."
  type        = string
  default     = "10m"
}

variable "target_group_arns" {
  type    = list(string)
  default = []
}

variable "load_balancers" {
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

variable "extra_block_device_mappings" {
  type = list(map(string))
  default = [
  ]
}

variable "asg" {
  type = object({
    min     = number
    max     = number
    desired = number
  })
}

variable "spot" {
  default = false
  type    = bool
}

variable "min_elb_capacity" {
  type    = number
  default = null
}
