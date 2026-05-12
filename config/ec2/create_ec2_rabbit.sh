#!/bin/bash

if [ $# -lt 2 ]
then
	echo "Usage: `basename $0` <name> <ip> [type]"
	exit 1
fi

NAME=$1
IP=$2
AMI="ami-3d4ff254"
KEY="rabbitserver"
TYPE="m1.small"
REGION="us-east-1"
OUT=/tmp/ec2_create_instances.out.txt

if [ $# -ge 3 ]; then TYPE=$3; fi

ec2-run-instances \
	$AMI \
	--key $KEY \
	--instance-type $TYPE \
	--region $REGION \
	--user-data-file rabbit-ec2-user-data.sh \
	--group default --group RabbitMQ \
	> $OUT
	
for instance in $(cat $OUT  | grep "^INSTANCE" | cut -f 2)
do
	echo CREATED INSTANCE $instance
	ec2-create-tags $instance --tag Name="$NAME"
	if [ "$IP" != "" ]; then
		ec2-associate-address $IP -i $instance
	fi
done

