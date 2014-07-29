#!/bin/bash
#
# yabt-mysql.sh
#
# Description:
# Make a MySQL backup database-by-database.
# Each backup is made on a work file, compared to a previous backup and replace it only if change.
#
# History:
# 18/07/2014 - Fabiano Martins - Initial version

mysql_version()
{
	YABT_MSG_ERR="identify MySQL version"
	AUX1="$(${MYSQL_CMD} -N -e "show variables like 'version';")"

	YABT_MSG_ERR="identify MySQL version (step 2/3)"

	YABT_MSG_ERR="identify MySQL version (step 3/3)"
	AUX3="$(echo ${AUX2} | cut -f1-2 -d'.')"

	echo ${AUX3}
}

yabt_init()
{
	# Defines command line based on loaded configurations
	MYSQL_CMD="mysql -u${YABT_USER} -p${YABT_PASS} -h${YABT_HOST} -P${YABT_PORT} -s "
	MYSQLDUMP_CMD="mysqldump -u${YABT_USER} -p${YABT_PASS} -h${YABT_HOST} -P${YABT_PORT} "
}

# List databases to dump
yabt_list_databases()
{
	YABT_MSG_ERR="list databases"
	for DATABASE in $(${MYSQL_CMD} -N -e "show databases") ; do
		echo "${DATABASE}"
	done
	unset YABT_MSG_ERR
}

yabt_dump_database()
{
	${MYSQLDUMP_CMD} $1
}

# Generic yabt run
. "$(dirname $0)/yabt.sh"
if [ $? != 0 ] ; then
	echo "environment initialization error" 1>&2
	exit 1
fi

exit 0
