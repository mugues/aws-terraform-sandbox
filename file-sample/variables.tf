variable "access_key" {}
variable "secret_key" {}


variable "aws_region" {
  default = "eu-central-1"
}

variable "key_name" {
  description = "Desired name of AWS key pair"
  default = "mugues-keypair"
}

variable "project_tag"
{
  description = "the global project tag name (must be all lowercase)"
  default = "aws-file-lab"
}


