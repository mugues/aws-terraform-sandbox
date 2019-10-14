variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {
  default = "eu-west-1"
}

variable "aws_amis" {
  type = "map"
  default = {
    "eu-central-1" = "ami-5652ce39"
    "eu-west-1" = "ami-3bfab942"
    "eu-west-2" = "ami-dff017b8"
  }
}

variable "aws_instance_type" {
  type = "map"
  default = {
    "eu-central-1" = "t2.micro"
    "eu-west-1" = "t1.micro"
    "eu-west-2" = "t2.micro"
  }
}


