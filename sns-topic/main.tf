
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



resource "aws_sns_topic" "guard_duty_findings_sns" {
  name = "guard-duty-findings-sns"
}


resource "aws_sns_topic_subscription" "guard_duty_findings_sqs_target" {
  topic_arn = "${aws_sns_topic.guard_duty_findings_sns.arn}"
  protocol  = "sqs"
  endpoint  = "${aws_sqs_queue.guard_duty_findings_queue.arn}"
}


resource "aws_sqs_queue" "guard_duty_findings_queue" {
  name = "guard-duty-findings-queue"
}

resource "aws_cloudwatch_event_target" "sqs" {
  rule      = "${aws_cloudwatch_event_rule.guard_duty_rule_execute_lambda.name}"
  arn       = "${aws_sqs_queue.guard_duty_findings_queue.arn}"
  input_transformer = { input_paths  = {masterAccount = "$.account", memberAccount = "$.detail.accountId", type = "$.detail.type", instanceId = "$.detail.resource.instanceDetails.instanceId"},
                        input_template = "{\"masterAccount\":<masterAccount>, \"memberAccount\":<memberAccount>, \"projectTag\":${var.project_tag}, \"type\":<type>, \"instanceId\":<instanceId>}"
                      }


}



resource "aws_sqs_queue_policy" "send_mesage_to_sqs_policy" {
  queue_url = "${aws_sqs_queue.guard_duty_findings_queue.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.guard_duty_findings_queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_cloudwatch_event_rule.guard_duty_rule_execute_lambda.arn}"
        }
      }
    }
  ]
}
POLICY
}
