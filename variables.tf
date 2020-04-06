variable "name" {
  default = "tf-firelens-demo"
}

variable "admin_cidr" {
  default = "0.0.0.0/0"
}

variable "public_key" {
}

variable "enable_fargate_httpbin_cloudwatch" {
  default = false
}

variable "enable_fargate_httpbin_firehose" {
  default = false
}

variable "enable_ec2_httpbin_firehose" {
  default = false
}