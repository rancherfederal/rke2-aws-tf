variable "name" {
  type = string
}

variable "token" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
