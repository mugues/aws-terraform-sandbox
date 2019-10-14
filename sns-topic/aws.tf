provider "aws" {
  region = "eu-west-1"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

provider "aws.apim.dev" {
  region = "eu-west-1"
  access_key = "AKIAJTA6LZB6MQN67YCQ"
  secret_key = "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"
}