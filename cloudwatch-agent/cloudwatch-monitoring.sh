#!/bin/bash

echo 'installing CloudWatchAgent'
wget https://s3.amazonaws.com/amazoncloudwatch-agent/linux/amd64/latest/AmazonCloudWatchAgent.zip
unzip AmazonCloudWatchAgent.zip
sudo ./install.sh
echo 'installed CloudWatchAgent'


echo 'creating config file for CloudWatchAgent'
cat <<EOF >/opt/aws/amazon-cloudwatch-agent/bin/config.json
{
	"logs": {
		"logs_collected": {
			"files": {
				"collect_list": [
					{
						"file_path": "/var/log/messages",
						"log_group_name": "/var/log/messages"
					},
					{
						"file_path": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log",
						"log_group_name": "amazon-cloudwatch-agent.log",
						"log_stream_name": "amazon-cloudwatch-agent.log",
						"timezone": "UTC"
					},
					{
						"file_path": "/var/log/${project_tag}/${project_tag}.log",
						"log_group_name": "/var/log/${project_tag}/${project_tag}.log",
						"log_stream_name": "/var/log/${project_tag}/${project_tag}.log",
						"timezone": "UTC"
					}
				]
			}
		}
	},
	"metrics": {
		"append_dimensions": {
			"AutoScalingGroupName": "\$${aws:AutoScalingGroupName}",
			"ImageId": "\$${aws:ImageId}",
			"InstanceId": "\$${aws:InstanceId}",
			"InstanceType": "\$${aws:InstanceType}"
		},
		"metrics_collected": {
			"cpu": {
				"measurement": [
					"cpu_usage_idle",
					"cpu_usage_iowait",
					"cpu_usage_user",
					"cpu_usage_system"
				],
				"metrics_collection_interval": 60,
				"totalcpu": false
			},
			"disk": {
				"measurement": [
					"used_percent",
					"inodes_free"
				],
				"metrics_collection_interval": 60,
				"resources": [
					"*"
				]
			},
			"diskio": {
				"measurement": [
					"io_time"
				],
				"metrics_collection_interval": 60,
				"resources": [
					"*"
				]
			},
			"mem": {
				"measurement": [
					"mem_used_percent",
					"mem_used",
                    "mem_cached",
                    "mem_total"
				],
				"metrics_collection_interval": 60
			},
			"swap": {
				"measurement": [
					"swap_used_percent"
				],
				"metrics_collection_interval": 60
			}
		}
	}
}
EOF
echo 'created config file CloudWatchAgent'


echo 'starting CloudWatchAgent'
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
echo 'started CloudWatchAgent'