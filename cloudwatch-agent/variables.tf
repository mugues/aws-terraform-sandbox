variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {}
variable "aws_key_name" {
  description = "Desired name of AWS key pair"
  default = "mugues-keypair"
}

variable "project_tag" {
  default = "mugues"
}

variable "aws_key_path" {
  description = "key location"
  default = "~/.ssh/mugues-keypair.pub"
}

variable "aws_amis" {
  type = "map"
  default = {
    "eu-central-1" = "ami-5652ce39"
    "eu-west-1" = "ami-d834aba1"
  }
}
