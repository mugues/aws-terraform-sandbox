variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {
  default = "eu-west-1"
}
variable "aws_key_pair_name" {
  description = "Desired name of AWS key pair"
  default = "mugues-keypair"
}

variable "aws_public_key_dir" {
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

variable "dashboard_name" {
  default = "telegraf-dashboard"
}


