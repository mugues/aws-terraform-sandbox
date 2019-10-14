#!/bin/bash

echo '${log_prefix} installing with yum ${application}'
yum -y install ${application}
service ${application} start
echo '${log_prefix} ${application} installed with yum'
