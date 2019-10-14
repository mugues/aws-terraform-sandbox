provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.main.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.main.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}


resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
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
    "Statement": [
        {
            "Sid": "CloudWatchAgentServerPolicy",
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}


module "change-sshd-port" "change-sshd-port"{
  source = "git::https://gitit.post.ch/scm/csb/aws-lz-terraform-modules.git//change-sshd-port?ref=aws-lz-terraform-modules-00.00.28.00"
  project_tag="mugues"
  sshd_port = "443"
}

data  "template_file" "telegraf_install" {
  template = "${file("${path.module}/telegraf-install.sh")}"
  vars {
    application = "telegraf"
    autoscaling_group_name = "mugues-asg"

  }
}

data "template_cloudinit_config" "config" {
  gzip = false
  base64_encode = false

  part {
    content = "${module.change-sshd-port.rendered}"
  }

  part {
    content      = "${data.template_file.telegraf_install.rendered}"
  }
}


resource "aws_launch_configuration" "as_conf" {
  image_id      = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
  user_data = "${data.template_cloudinit_config.config.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.web_instance_profile.id}"
  associate_public_ip_address = true


  lifecycle {
    create_before_destroy = true
  }

  key_name = "${var.aws_key_pair_name}"

}

resource "aws_autoscaling_group" "scaling_group" {
  name                 = "mugues-asg"
  launch_configuration = "${aws_launch_configuration.as_conf.name}"
  vpc_zone_identifier       = ["${aws_subnet.default.*.id}"]

  min_size             = 2
  max_size             = 2


  lifecycle {
    create_before_destroy = true
  }

  tag {
    key = "Name"
    value = "mugues-ec2"
    propagate_at_launch = true

  }
}


resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.dashboard_name}"
  dashboard_body = <<EOF
   {
      "widgets": [
          {
             "type":"metric",
             "x":0,
             "y":0,
             "width":12,
             "height":6,
             "properties":{
                "metrics":[
                   [ "Telegraf", "cpu_usage_user", "AutoScalingGroupName", "${aws_autoscaling_group.scaling_group.name}" ]
                ],
                "period":300,
                "stat":"Average",
                "region":"${var.aws_region}",
                "title":"EC2 Instance CPU"
             }
          },
          {
             "type":"text",
             "x":0,
             "y":7,
             "width":3,
             "height":3,
             "properties":{
                "markdown":"Hello world"
             }
          }
      ]
    }
    EOF
}

output "ami" {
  value = "${lookup(var.aws_amis, var.aws_region)}"
}

output "cloudinit_config" {
  value = "${data.template_cloudinit_config.config.rendered}"
}
