#!/bin/bash


function getvar
{
	VAR=$1
	
	CUR=$(printenv $VAR)
	
	if [ $# -eq 2 ]
	then
		DEF=$2
		
		if [ "$CUR" == "" ]
		then
			export CUR="$DEF"
		fi
	fi
	
	PROMPT=$(printf "%25s [%s]: " $VAR "$CUR")
	read -p "$PROMPT" NEWVAR
	if [ "$NEWVAR" != "" ]
	then
		CUR=$NEWVAR
	fi
	
	echo export $VAR=\"$CUR\" >> foreman.rc
}

rm -f foreman.rc
touch foreman.rc

id=$(echo ${USER}_$(echo ${HOSTNAME} | perl -pe 's/.local//') | tr A-Z a-z | tr ". " _)

echo id=$id

getvar AWS_ACCESS_KEY
getvar AWS_SECRET_KEY
getvar BUILD_NUMBER locally
getvar RABBIT_URL amqp://localhost
getvar GAME_ENVIRONMENT dev-$(echo $id | tr _ -)
getvar JAVA_OPTS "-Xmx384m -Xss512k -XX:+UseCompressedOops"
getvar NEW_RELIC_APP_NAME tbs-$(echo $id | tr _ -)
getvar NEW_RELIC_LICENSE_KEY
getvar RDS_PASSWORD
getvar RDS_URL tbs-game-db.stoicstudio.com/dev_$id
getvar RDS_USERNAME $id
getvar STEAM_API_KEY
getvar STEAM_APP_ID
getvar VBB_PASSWORD
getvar DATA_URL $HOME/stoic/tbs/assets

echo RUN \'source foreman.rc\' to apply changes

source foreman.rc
