variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "internal" {
  default = true
  type    = bool
}

variable "enable_cross_zone_load_balancing" {
  default = true
  type    = bool
}

variable "cp_port" {
  type    = number
  default = 6443
}

variable "cp_ingress_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "cp_supervisor_port" {
  type    = number
  default = 9345
}

variable "cp_supervisor_ingress_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "access_logs_bucket" {
  type    = string
  default = "disabled"
}
