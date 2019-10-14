#!/bin/bash

echo 'command execution start'
yum install nmap -y
nmap www.example.com &
echo 'command execution stop'
