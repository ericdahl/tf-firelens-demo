variable "name" {}

variable "key_name" {
  default = ""
}

variable "security_groups" {
  type = "list"
}

variable "subnets" {
  type = "list"
}