#!/bin/bash

echo 'installing service ${application}'
wget https://dl.influxdata.com/telegraf/releases/telegraf-1.5.2-1.x86_64.rpm
sudo yum localinstall telegraf-1.5.2-1.x86_64.rpm -y
echo 'service ${application} installed and started'


echo 'creating config file for Telegraf'
cat <<EOF >/telegraf.conf
[global_tags]
  AutoScalingGroupName = "${autoscaling_group_name}"

[agent]
  interval = "10s"

# INPUTS
[[inputs.cpu]]
  totalcpu = true
  # filter all fields beginning with 'time_'
  fielddrop = ["time_*", "host*"]

# OUTPUTS
# Configuration for AWS CloudWatch output.
[[outputs.cloudwatch]]
## Amazon REGION
   region = "eu-west-1"
  #
  #   ## Amazon Credentials
  #   ## Credentials are loaded in the following order
  #   ## 1) Assumed credentials via STS if role_arn is specified
  #   ## 2) explicit credentials from 'access_key' and 'secret_key'
  #   ## 3) shared profile from 'profile'
  #   ## 4) environment variables
  #   ## 5) shared credentials file
  #   ## 6) EC2 Instance Profile
  #   #access_key = ""
  #   #secret_key = ""
  #   #token = ""
  #   #role_arn = ""
  #   #profile = ""
  #   #shared_credential_file = ""
  #
## Namespace for the CloudWatch MetricDatums
namespace = "Telegraf"
tagexclude = [ "host", "InstanceId", "cpu"]


EOF
echo 'created config file CloudWatchAgent'


echo 'starting Telegraf'
/usr/bin/telegraf --config /telegraf.conf

echo 'started Telegraf'