variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {
  default = "eu-central-1"
}
variable "key_name" {
  description = "Desired name of AWS key pair"
  default = "mugues-keypair"
}

variable "public_key_path" {
  description = "key location"
  default = "~/.ssh/mugues-keypair.pub"
}

variable "private_key_path" {
  description = "key location"
  default = "~/.ssh/mugues-keypair"
}

variable "aws_amis" {
  type = "map"
  default = {
    "eu-central-1" = "ami-5652ce39"
    "us-west-2" = "ami-4b32be2b"
  }
}
