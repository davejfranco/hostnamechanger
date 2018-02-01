# <center>Hostname Changer script </center>

This script will change Ec2 instance hostname based on Tag:Name 

## How does it works?
Easy, just ask Dave... it will check its own instance Tag:Name and if different to the current hostname it will perform some magic and that's it. 

## Requirements
* pip
* awscli
* jq

## Note

The ec2 IAM profile will require Ec2 Describe permission in order to read its own tag:Name