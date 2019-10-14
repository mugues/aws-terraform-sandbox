resource "aws_instance" "web" {
  count = "${(terraform.workspace) == "prod" ? 2 : 1}"

  ami           = "ami-5652ce39"
  instance_type = "t2.micro"

  tags {
    Name = "web - ${terraform.workspace}"
  }
}
resource "aws_eip" "web" {
  /*lifecycle {
    prevent_destroy = true
  }*/
}