provider "aws" {
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key_id
  region     = var.aws_region
}
provider "aws" {
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key_id
  region     = "us-east-1"
  alias      = "virginia"
}