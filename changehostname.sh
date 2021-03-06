#!/bin/bash

#There is DOMAIN variable right now is set to "example.local"
EC2ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq .region -r)
TAGS=$(aws ec2 describe-instances --instance-ids $EC2ID --region $REGION | jq ."Reservations"[0]."Instances"[0]."Tags")

#Check response before doing anything
if [[ ( -z $EC2ID ) || ( -z $REGION ) || ( -z $TAGS ) ]];
then
	exit 0
fi

for n in $(seq 0 $(echo $TAGS | jq '.[] | length' | wc -l)); #find a better way to do this
do
        KEY=$(echo $TAGS | jq .[$n]."Key")
        if [[ $KEY == '"Name"' ]]; then
            NAME=$(echo $TAGS | jq .[$n]."Value" -r)
            break
        else:
                echo "Unable to find Tag:Name"
                exit 1
        fi
done

if [ ! -z $(cat /etc/issue | grep -o "Ubuntu") ];
then
	#Ubuntu
	OLDNAME=$(cat /etc/hostname)
	if [ $OLDNAME == $NAME ];
	then
		exit 0
	fi
	#Replace string
	sed -i "s/${OLDNAME}/${NAME}/g" /etc/hostname

	#On Ubuntu add hostname to /etc/hosts if is not there
	if [ -z $(head -n 2 /etc/hosts | tail -n 1) ];
	then
		sed -i "2i\127.0.0.1 $NAME" /etc/hosts
	else
		sed -i "s/${OLDNAME}/${NAME}/g" /etc/hosts
	fi
fi

if [ ! -z $(cat /etc/issue | grep -o "Amazon") ];
then

	DOMAIN="example.local"
	OLDNAME=$(cat /etc/sysconfig/network | grep  "HOSTNAME" | cut -d "=" -f2)
	FQDN=$(echo $NAME"."$DOMAIN)
	OLDHOST=$(echo $OLDNAME | cut -d "." -f1)
	if [ $OLDHOST == $NAME ];
	then
		exit 0
	fi
	#Replace string
	sed -i "s/${OLDNAME}/${FQDN}/g" /etc/sysconfig/network
	if [ -z $(cat /etc/hosts | grep "$OLDHOST") ];
	then
		#sed -i "3i\127.0.0.1 ${NAME}" /etc/hosts
		echo "127.0.0.1  $NAME"
	else
		sed -i "s/${OLDHOST}/${NAME}/g" /etc/hosts
	fi
fi

#Reboot Instance
reboot
