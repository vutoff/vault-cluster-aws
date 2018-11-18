variable "ssl_certificate_id" {}
variable "ami_id" {}
variable "key_name" {}

variable "public_zone_id" {
  default = ""
}

variable "private_zone_id" {
  default = ""
}

variable "public_subnet_ids" {
  type = "list"
}

variable "private_subnet_ids" {
  type = "list"
}

variable "security_groups" {
  type = "list"
}

variable "main_vars" {
  type = "map"
}

variable "service_vars" {
  type = "map"
}

variable "network_vars" {
  type = "map"
}
