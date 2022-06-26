variable "aws_id" {}
variable "aws_access_key_id" {}
variable "aws_secret_access_key_id" {}
variable "aws_region" {}
variable "domain_name" {}
variable "domain_host_name" {}

locals {
  fqdn = {
    name = "${var.domain_host_name}.${var.domain_name}"
  }
  bucket = {
    name = local.fqdn.name
  }
}