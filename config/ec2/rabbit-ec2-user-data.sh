#!/bin/sh
cat <<EOF > /etc/apt/sources.list.d/rabbitmq.list
deb http://www.rabbitmq.com/debian/ testing main
EOF

curl http://www.rabbitmq.com/rabbitmq-signing-key-public.asc -o /tmp/rabbitmq-signing-key-public.asc
apt-key add /tmp/rabbitmq-signing-key-public.asc
rm /tmp/rabbitmq-signing-key-public.asc

apt-get -qy update
apt-get -qy install rabbitmq-server

echo "*** `basename $0` ENABLING rabbitmq_management"

HOME=/root rabbitmq-plugins enable rabbitmq_management

echo "*** `basename $0` RESTARTING RABBIT"

/etc/init.d/rabbitmq-server restart
