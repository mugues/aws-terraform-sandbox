#!/bin/bash

echo 'installing service ${application}'
yum -y install ${application}
service ${application} start
echo 'service ${application} installed and started'
