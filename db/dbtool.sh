#!/bin/bash

###############################################################
#
###############################################################

usage()
{
cat << EOF
usage: $0 options operation

This script replaces a database schema

OPTIONS:
   -h                    Show this message
   -r      <release>     Deployment release, e.g. "qa", "live", "username_machine"
   -i      <instance>    DB instance, e.g. "metrics", "game"
   -b      <branch>      Deployment branch, e.g. "dev"
   -k                    Recreate the database prior to executing
   -v                    Verbose
   -a                    Use ADMIN account (stoicdb)
   -H      <host>        Override HOST
   -U      <user>        Override USER
   
OPERATIONS:
   -x      <source>      Execute SQL from file source
   -s                    Read DB schema to stdout
   -A                    Read entire DB to stdout
   -g                    Get DB Version
   -V      <version>     Set DB Version
   -u      <version>     Update to version number

EOF
}

if [ $# -lt 1 ]
then
        usage
        exit 1
fi

ADMIN=0
BRANCH=dev
RECREATE=0
VERBOSE=0
INSTANCE=game
RELEASE=$(whoami)_$(hostname | cut -f 1 -d .)

###############################################################
#
###############################################################

while getopts "hai:b:r:kx:sAvgu:V:H:" OPTION
do
	case $OPTION in
		h)
			usage
			exit 1
			;;
		a)
			export ADMIN=1
			;;
		i)
			export INSTANCE=$OPTARG
			;;
		b)
			export BRANCH=$OPTARG
			;;
		r)
			export RELEASE=$OPTARG
			;;
		k)
			export RECREATE=1
			;;
		x)
			export OPERATION="execute"
			export SOURCE=$OPTARG
			;;
		s)
			export OPERATION="read"
			;;
		A)
			export OPERATION="read_all"
			;;		
		g)
			export OPERATION="get_version"
			;;		
		V)
			export OPERATION="set_version"
			TO_VERSION=$OPTARG
			;;		
		u)
			export OPERATION="update_version"
			TO_VERSION=$OPTARG
			;;
		H)
			HOST=$OPTARG
			;;					
		v)
			export VERBOSE=1
			;;
		?)
			usage
			exit 1
			;;
	esac
done

###############################################################
#
###############################################################

if [[ -z $INSTANCE ]] || [[ -z $BRANCH ]] || [[ -z $RELEASE ]]
then
		echo ERROR: Missing Arguments.
		usage
		exit 1
fi

if [ "$BRANCH" != "dev" ]; then echo INVALID BRANCH '$BRANCH'; exit 1; fi

if [ "$INSTANCE" != "game" ] && [ "$INSTANCE" != "metrics" ]; then echo INVALID INSTANCE $INSTANCE; exit 1; fi

export DBNAME="${BRANCH}_${RELEASE}"

if [ -z "$HOST" ]; then
	HOST="tbs-${INSTANCE}-db.stoicstudio.com"
	echo setting HOST=$HOST
fi

if [ "$ADMIN" -eq 1 ]; then
	USER=stoicdb
else
	USER="${RELEASE}"
fi

if [ "$VERBOSE" -eq 1 ]; then
	echo "-- USER=$USER"
	echo "-- HOST=$HOST"
	echo "-- DBNAME=$DBNAME"
	echo "-- SOURCE=$SOURCE"
fi

DB_PASSWD_ARG=""

if [ "$DB_PASSWD" != "" ]; then
	DB_PASSWD_ARG="=$DB_PASSWD"
fi

###############################################################
#
###############################################################

function do_execute
{
	CMD="START TRANSACTION;"
	
	if [ "$RECREATE" -eq 1 ]; then
		CMD="${CMD}DROP DATABASE IF EXISTS $DBNAME;CREATE DATABASE $DBNAME DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;";
	else
		CMD="${CMD}CREATE DATABASE IF NOT EXISTS $DBNAME  DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;";
	fi

	CMD="${CMD}USE $DBNAME; SOURCE $SOURCE;COMMIT;"
	
	if [ "$VERBOSE" -eq 1 ]; then
		echo "-- Executing $CMD"
	fi
	
	echo $CMD | mysql --user=$USER --password$DB_PASSWD_ARG --host=$HOST

	exit $?
}

###############################################################
#
###############################################################

function do_read
{
	mysqldump --user=$USER --password$DB_PASSWD_ARG --no-data --host=$HOST $DBNAME
	exit $?
}

###############################################################
#
###############################################################

function do_read_all
{
	mysqldump --user=$USER --password$DB_PASSWD_ARG --host=$HOST $DBNAME
	exit $?
}

###############################################################
#
###############################################################

function do_get_version
{
	CMD="USE $DBNAME; SELECT version_number from version;" 
	
	RESULTS=$(echo $CMD | mysql --skip_column-names --user=$USER --password$DB_PASSWD_ARG --host=$HOST)

	if [ $? -ne 0 ]; then exit 1; fi

	echo $RESULTS
	
	exit $?
}

###############################################################
#
###############################################################

VERSION_TABLE="\`version\`"

function get_version_set_sql
{
	echo "\
		DELETE FROM \`version\` LIMIT 1;\
		REPLACE INTO \`version\` (\`version_number\`) VALUES(${1});"
}

###############################################################
#
###############################################################

function do_set_version
{
	VERSION_SQL=$(get_version_set_sql $TO_VERSION)
	
	#echo VERSION_SQL=$VERSION_SQL
	
	CMD="USE $DBNAME;START TRANSACTION;${VERSION_SQL};COMMIT;"
	
	echo CMD=$CMD
	
	echo $CMD | mysql --user=$USER --password$DB_PASSWD_ARG --host=$HOST
	
	exit $?
}


###############################################################
#
###############################################################

function get_latest_version
{
	ls -1 $1 | sort -n | tail -1
}

###############################################################
#
###############################################################

function do_recreate_database()
{
	CMD="DROP DATABASE IF EXISTS $DBNAME;CREATE DATABASE $DBNAME;";
	echo $CMD | mysql --user=$USER --password$DB_PASSWD_ARG --host=$HOST
	return $?
}

function do_update_version
{	

	if [ "$TO_VERSION" = "latest" ]; then
		echo "-- Looking for LATEST version on $INSTANCE..."
		TO_VERSION=$(get_latest_version $INSTANCE)
	fi
	
	VERSION_SQL=$(get_version_set_sql $TO_VERSION)
	
	FROM_VERSION=$(do_get_version)
	
	if [ $? -ne 0 ] || [ "$FROM_VERSION" = "" ]; then 
		echo "-- No version number found, starting from fresh"
		FROM_VERSION=-1
	else
		echo "-- Got version [$FROM_VERSION]"
	fi
		
	echo "-- FROM_VERSION=$FROM_VERSION"
	echo "-- TO_VERSION=$TO_VERSION"
		
	CMD="START TRANSACTION;CREATE DATABASE IF NOT EXISTS $DBNAME;USE $DBNAME;START TRANSACTION;"
	
	if [ "$TO_VERSION" -gt "$FROM_VERSION" ]; then
		echo "-- Upgrading from version $FROM_VERSION to $TO_VERSION"
		v=$((FROM_VERSION+1))
		
		while [ $v -le $TO_VERSION ]; do
			CMD="${CMD}SOURCE $INSTANCE/$v/apply.sql;"
			v=$((v+1))
		done
	elif [ "$TO_VERSION" -lt "$FROM_VERSION" ]; then
		echo "-- Downgrading from version $FROM_VERSION to $TO_VERSION"
		v=$((FROM_VERSION))
		
		while [ $v -ge $TO_VERSION ]; do
			CMD="${CMD}SOURCE $INSTANCE/$v/undo.sql;"
			v=$((v-1))
		done
	else
		echo "-- Already at version $TO_VERSION"
		exit 0
	fi

	CMD="${CMD}${VERSION_SQL};"
	
	CMD="${CMD}COMMIT;"
	
	echo CMD=$CMD
	
	echo $CMD | mysql --user=$USER --password$DB_PASSWD_ARG --host=$HOST
	
	exit $?
}


###############################################################
#
###############################################################

if [ "$VERBOSE" -eq 1 ]; then
	echo "-- OPERATION=$OPERATION"
fi
	
if [ "$RECREATE" -eq 1 ]; then
	do_recreate_database
fi

case $OPERATION in
	execute)
		do_execute
		;;
	read)
		do_read
		;;
	read_all)
		do_read_all
		;;
	get_version)
		do_get_version
		;;
	set_version)
		do_set_version
		;;
	update_version)
		do_update_version
		;;
esac
