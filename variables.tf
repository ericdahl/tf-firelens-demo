variable "admin_cidr" {
}

variable "public_key" {
}

variable "enable_fargate_httpbin_cloudwatch" {
  default = "false"
}

variable "enable_fargate_httpbin_firehose" {
  default = "false"
}
