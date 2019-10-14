provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

resource "aws_guardduty_detector" "master" {
}

resource "aws_guardduty_member" "member" {
  count = "${length(var.members_account_number)}"

  account_id  = "${lookup(var.members_account_number[count.index], "accountNumber")}"
  detector_id = "${aws_guardduty_detector.master.id}"
  email       = "${lookup(var.members_account_number[count.index], "accountEmail")}"
}


resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "policy_stop_ec2_instance" {
  count = "${length(var.members_account_number)}"
  description = "A policy to stop ec2 instances and create logs"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ec2:Stop*"],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": ["arn:aws:logs:*:*:*"]
    },
    {
      "Effect": "Allow",
      "Action": ["sts:AssumeRole"],
      "Resource": "arn:aws:iam::${lookup(var.members_account_number[count.index], "accountNumber")}:role/EC2StopInstancesRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attachment" {
  count = "${length(var.members_account_number)}"

  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "${element(aws_iam_policy.policy_stop_ec2_instance.*.arn, count.index)}"


}