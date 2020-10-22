variable "name" {
  type = string
}

variable "policies" {
  type = list(object({
    name   = string
    policy = string
  }))

  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}