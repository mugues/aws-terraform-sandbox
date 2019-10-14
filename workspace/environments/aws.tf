provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

terraform {
    backend "s3" {
        bucket = "mugues-s3-terraform-backend"
        dynamodb_table = "mugues-s3-terraform-state-lock-dynamo"
        key = "terraform.tfstate"
        region = "eu-central-1"
    }
}

