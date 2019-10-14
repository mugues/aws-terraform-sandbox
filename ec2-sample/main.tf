provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  # vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "change-sshd-port" "change-sshd-port"{
  source = "git::https://uguesm@gitit.post.ch/scm/csb/aws-lz-terraform-modules.git//change-sshd-port?ref=v0.0.1"
  project_tag="${var.project_tag}"
  sshd_port = "${var.sshd_port}"
}

data  "template_file" "app_install" {
  template = "${file("${path.module}/app-install.sh")}"
  vars {
    application = "nginx"
  }
}

data "template_file" "cloudwatch-monitoring" {
  template = "${file("${path.module}/cloudwatch-monitoring.sh")}"
}

data "template_cloudinit_config" "config" {
    gzip = false
    base64_encode = false

  # part {
  #   order = 1
  #   content_type = "text/x-shellscript"
  #   content = "${file("files/stripe-ephemeral-volumes.sh")}"
  # }

  part {
    content      = "${data.template_file.app_install.rendered}"
  }

  part {
    content      = "${data.template_file.app_install.rendered}"
  }

  # get master user_data
  part {
    content      = "${data.template_file.cloudwatch-monitoring.rendered}"
  }
}


resource "aws_key_pair" "auth" {
  key_name   = "${var.aws_key_pair_name}"
  public_key = "${file(var.aws_public_key_dir)}"
}


resource "aws_iam_role" "web_iam_role" {
  name = "mugues-web_iam_role"
  assume_role_policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Action": "sts:AssumeRole",
			"Principal": {
				"Service": "ec2.amazonaws.com"
			},
			"Effect": "Allow",
			"Sid": ""
		}
	]
}
EOF
}

resource "aws_iam_instance_profile" "web_instance_profile" {
  name = "mugues-web_instance_profile"
  role = "${aws_iam_role.web_iam_role.id}"
  depends_on = ["aws_iam_role.web_iam_role"]
}

resource "aws_iam_role_policy" "web_iam_role_policy" {
  name = "mugues-web_iam_role_policy"
  role = "${aws_iam_role.web_iam_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "stmt1",
    "Effect": "Allow",
    "Action": ["s3:GetObject", "ec2:Describe*"],
    "Resource": "*"
    }]
}
EOF
}

# Change the aws_instance we declared earlier to now include "depends_on"
resource "aws_instance" "mugues-ec2-terraform" {
  ami           = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type = "t2.micro"
  user_data = "${data.template_cloudinit_config.config.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.web_instance_profile.id}"
  tags  {
    Name = "mugues-ec2-terraform"
  }

  associate_public_ip_address = true

  # The name of our SSH keypair we created above.
  key_name = "${aws_key_pair.auth.id}"

}

# Change the aws_instance we declared earlier to now include "depends_on"
resource "aws_instance" "mugues-ec2-terraform1" {
  ami           = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type = "t2.micro"
  user_data = "${data.template_cloudinit_config.config.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.web_instance_profile.id}"
  tags  {
    Name = "mugues-ec2-terraform1"
  }

  associate_public_ip_address = true

  # The name of our SSH keypair we created above.
  key_name = "${aws_key_pair.auth.id}"

}

resource "aws_eip" "ip" {
  instance = "${aws_instance.mugues-ec2-terraform.id}"
}

output "ami" {
  value = "${lookup(var.aws_amis, var.aws_region)}"
}

output "ip" {
  value = "${aws_eip.ip.public_ip}"
}

output "cloudinit_config" {
  value = "${data.template_cloudinit_config.config.rendered}"
}
