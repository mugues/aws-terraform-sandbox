resource "aws_guardduty_detector" "master" {
  enable = true
}


resource "aws_guardduty_detector" "member" {
  provider = "aws.apim.dev"
  enable = true
}

resource "aws_guardduty_member" "member" {
  account_id  = "${aws_guardduty_detector.member.account_id}"
  detector_id = "${aws_guardduty_detector.master.id}"
  email       = "massimo.ugues@post.ch"
}


resource "aws_s3_bucket_object" "object" {
  bucket = "${var.s3_bucket}"
  key    = "${var.s3_key}"
  source = "./aws-lz-lambda-1.0-SNAPSHOT.jar"
  acl    = "private"

  # Tells Terraform that this EC2 instance must be created only after the
  # S3 bucket has been created.
  # depends_on = ["aws_s3_bucket.appl_dev"]
}


resource "aws_cloudwatch_event_rule" "guard_duty_rule_execute_lambda" {
  name        = "guard-duty-rule-execute-lambda"
  description = "Execute lambda when is triggered a findings"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.guardduty"
  ]
}
PATTERN
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = "${aws_cloudwatch_event_rule.guard_duty_rule_execute_lambda.name}"
  arn       = "${aws_lambda_function.guard_duty_lambda.arn}"
}



resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id   = "AllowExecutionFromCloudWatch"
  action         = "lambda:InvokeFunction"
  function_name  = "${aws_lambda_function.guard_duty_lambda.function_name}"
  principal      = "events.amazonaws.com"
  source_arn     = "${aws_cloudwatch_event_rule.guard_duty_rule_execute_lambda.arn}"
}


resource "aws_lambda_function" "guard_duty_lambda" {
  function_name = "guard-duty-lambda"
  memory_size = 512
  timeout = 10

  # The bucket name as created earlier with "aws s3api create-bucket"
  s3_bucket = "${var.s3_bucket}"
  s3_key    = "${var.s3_key}"


  handler = "ch.post.aws.lz.lambda.GuardDutyFindingsLambda::handleRequest"
  runtime = "java8"

  role = "${aws_iam_role.iam_for_lambda.arn}"

  depends_on = ["aws_s3_bucket_object.object"]
}

# IAM role which dictates what other AWS services the Lambda function may access.
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
  name        = "test-policy"
  description = "A test policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Start*",
        "ec2:Stop*"
      ],
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
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attachment" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "${aws_iam_policy.policy_stop_ec2_instance.arn}"
}
