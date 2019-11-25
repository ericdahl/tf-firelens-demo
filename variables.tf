variable "admin_cidr" {
  default = ""
}

variable "public_key" {
  default = ""
}

variable "enable_fargate_httpbin_cloudwatch" {
  default = "false"
}

variable "enable_fargate_httpbin_firehose" {
  default = "false"
}
