# Specify the provider and access details
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.aws_region}"
}



resource "aws_s3_bucket" "appl_dev" {
  bucket = "mugues-sample-terraform"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags {
    Name = "${var.project_tag} S3 application Store"
  }
}


resource "aws_s3_bucket_object" "object" {
   bucket = "mugues-sample-terraform"
   key    = "webapp-0.0.1.jar"
   source = "./webapp-0.0.1.jar"
   acl    = "private"

   # Tells Terraform that this EC2 instance must be created only after the
   # S3 bucket has been created.
   depends_on = ["aws_s3_bucket.appl_dev"]
 }
