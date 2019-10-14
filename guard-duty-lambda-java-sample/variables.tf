variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {
  default = "eu-west-1"
}

variable "s3_bucket" {
  default = "mugues-terraform-serverless-example"
}

variable "s3_key" {
  default = "v1.0.0/aws-lz-lambda-1.0-SNAPSHOT.jar"
}
