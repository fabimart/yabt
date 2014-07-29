#!/bin/bash
#
# yabt-postgresql.sh
#
# Description:
# Make a PostgreSQL backup database-by-database.
# Each backup is made on a work file, compared to a previous backup and replace it only if change.
#
# History:
# 18/07/2014 - Fabiano Martins - Initial version

yabt_init()
{
	# Defines command line based on loaded configurations
	GENERIC_ARGS="--no-password"
	if [ ! -z "${YABT_HOST}" ] ; then
		GENERIC_ARGS="-h${YABT_HOST} ${GENERIC_ARG}"
	fi
	if [ ! -z "${YABT_PORT}" ] ; then
		GENERIC_ARGS="-h${YABT_PORT} ${GENERIC_ARG}"
	fi
	if [ ! -z "${YABT_USER}" ] ; then
		GENERIC_ARGS="-U${YABT_USER} ${GENERIC_ARG}"
	fi
	POSTGRESQL_CMD="psql ${GENERIC_ARGS} -t "
	POSTGRESQLDUMP_CMD="pg_dump ${GENERIC_ARGS} "
}

# List databases to dump
yabt_list_databases()
{
	# A ER do grep destina-se a eliminar linhas em branco, poderia tambem ser [a-z0-9_-], etc: o que interessa e' que tenha alguma conteudo, mas como nossos databases iniciam com letra minuscula, esta ER e' suficiente
	YABT_MSG_ERR="list databases"
	#${POSTGRESQL_CMD} -l | grep "^ [a-z]" | cut -f1 -d'|' | sed 's/ //g'
	for DATABASE in $(${POSTGRESQL_CMD} -l | grep "^ [a-z]" | cut -f1 -d'|' | sed 's/ //g'); do
		echo "${DATABASE}"
	done
	unset YABT_MSG_ERR
}

yabt_dump_database()
{
	${POSTGRESQLDUMP_CMD} $1
}

# Generic yabt run
. "$(dirname $0)/yabt.sh"
if [ $? != 0 ] ; then
	echo "environment initialization error" 1>&2
	exit 1
fi

exit 0
