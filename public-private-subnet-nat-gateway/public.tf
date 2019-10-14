/*
  Web Servers
*/
resource "aws_security_group" "web" {
    name = "vpc_web"
    description = "Allow incoming connections."

    ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.vpc_cidr}"]
    }


    vpc_id = "${aws_vpc.vpc.id}"

    tags {
        Name = "WebServerSG"
    }
}

data "template_file" "nginx-install" {
  template = "${file("./yum-install.sh")}"
  vars {
    log_prefix = "mugues"
    application = "nginx"
  }
}

data "template_cloudinit_config" "config" {
  gzip = false
  base64_encode = false

  part {
    content      = "${data.template_file.nginx-install.rendered}"
  }
}

resource "aws_instance" "web-1" {
    ami = "${lookup(var.amis, var.aws_region)}"
    availability_zone = "eu-west-1a"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${aws_security_group.web.id}"]
    subnet_id = "${aws_subnet.public_subnet_eu_west_1a.id}"
    associate_public_ip_address = true
    source_dest_check = false

    user_data = "${data.template_cloudinit_config.config.rendered}"
    tags {
        Name = "Web Server 1 Schedule"
        Schedule = "uk-weekends-hours"
    }
}

resource "aws_eip" "web-1" {
    instance = "${aws_instance.web-1.id}"
    vpc = true
}
