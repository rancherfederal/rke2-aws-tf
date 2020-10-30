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

variable "existing_statebucket" {
  type = string
  default = null
}

variable "aws_partition" {
  description = "AWS Partition for s3 buckets (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html)"
  type = string
  default = "aws"
}