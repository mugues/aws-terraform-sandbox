## cloudwatch-agent module
Terraform module which sets-up/creates everything needed to send application metrics and log files to CloudWatch

Pre-requisite:

The application's log file location and name must correspond to this pattern:
```
file = /var/log/${project_tag}/${project_tag}.log
```
where project_tag is one of the required module input parameters.


## How to import and use the module in your terraform project
If you want to import and use the module in your terraform project you can do it in this way:

```
module "cloudwatch-log" {
  source = "git::https://username@gitit.post.ch/scm/csb/aws-lz-terraform-modules.git//cloudwatch-log?ref=v0.0.18"
  aws_region = "${var.aws_region}"
  iam_role_id = "${aws_iam_role.iam_role.id}"
  log_retention_in_days = "${var.log_retention_in_days}"
  ...
}
```
where 
```
?ref=v0.0.18
```
is the tag of the aws-lz-terraform-modules latest release.

You also need to add the module's template_file part rendered in output to your template_cloudinit_config

```
data "template_cloudinit_config" "config" {
  gzip = false
  base64_encode = false

  part {
    content      = "${module.cloudwatch-log.rendered}"
  }

  part {
    content      = "${data.template_file.your_project_template_file.rendered}"
  }

  ...
} 
```

Please see https://gitit.post.ch/projects/CSB/repos/aws-lz-terraform/browse/terraform-lab/ec2-scaling-group/main.tf for a more complete module import example.

Troubleshoot

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a stop
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
/opt/aws/amazon-cloudwatch-agent/bin/config.json
 
