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
    from_port   = 440
    to_port     = 443
    protocol    = "tcp"
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
  source = "git::https://gitit.post.ch/scm/csb/aws-lz-terraform-modules.git//change-sshd-port?ref=aws-lz-terraform-modules-00.01.00.10"
  project_tag="mugues-tag"
  sshd_port = "443"
}

data  "template_file" "command-execution" {
  template = "${file("${path.module}/command-execution.sh")}"
}


data "template_cloudinit_config" "config" {
  gzip = false
  base64_encode = false

  part {
    content      = "${data.template_file.command-execution.rendered}"
  }

  part {
    content = "${module.change-sshd-port.rendered}"
  }

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
              "Service": [
                "ec2.amazonaws.com",
                "ssm.amazonaws.com"
              ]
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
    "Statement": [
        {
            "Sid": "statement1",
            "Effect": "Allow",
            "Action":[
            "s3:GetObject"
            ],
            "Resource": "*"
        }
      ]
}
EOF
}

data "aws_iam_policy" "AmazonEC2RoleforSSM" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "ssm-role-policy-attachment" {
  role = "${aws_iam_role.web_iam_role.id}"
  policy_arn = "${data.aws_iam_policy.AmazonEC2RoleforSSM.arn}"
}

# Change the aws_instance we declared earlier to now include "depends_on"
resource "aws_instance" "mugues-ec2-terraform" {
  count = 5
  ami           = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type = "${lookup(var.aws_instance_type, var.aws_region)}"
  user_data = "${data.template_cloudinit_config.config.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.web_instance_profile.id}"
  security_groups = ["${aws_security_group.allow_all.name}"]
  tags  {
    Name = "mugues-ec2-terraform"
  }

  associate_public_ip_address = true
  depends_on = ["aws_security_group.allow_all"]
}


