#!/bin/bash

if [ $# -ne 3 ]; then echo "args"; exit; fi

minutes=$1
server=$2
adminkey=$3

url=http://$server/services/admin/system_msg/0/$adminkey

echo shutdown server in $minutes minutes to $url
echo "[hit enter to continue]"

read

function set_system_msg
{
	curl -d "$1" $2
	if [ $? -ne 0 ]
	then
		echo "error curling: $?"
		exit
	fi
}

function send_alert {
	j=0
        while [ $j -lt 10 ] 
        do
            echo sending $1 to $2
            
			set_system_msg "$1" "$2"

            sleep 1
		j=$((j+1))
        done
}

i=$minutes
while [ $i -gt 0 ]
do
	echo noting minute $i

	msg="TBS:F Server Restart in $i Minutes"
	
	if [ $i -eq 1 ]
	then 
		msg="TBS:F Server Restart in $i Minute"
	fi

	send_alert "$msg" "$url"

	sleep 50
	
	i=$((i-1))

done

echo "All done" 

send_alert "TBS:F Server Restart Now" $url

sleep 10;

echo "Shutting Down."
