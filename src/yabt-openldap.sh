#!/bin/bash
#
# yabt-openldap.sh
#
# Description:
# Make a OpenLDAP backup database-by-database.
# Each backup is made on a work file, compared to a previous backup and replace it only if change.
#
# History:
# 18/07/2014 - Fabiano Martins - Initial version

list_databases_ids()
{
	${SLAPCAT_CMD} -b "cn=config" | grep "dn: olcDatabase=" | cut -f2 -d"{" | cut -f1 -d"," | grep -v "}frontend$" | grep -v "}monitor$" | cut -f1 -d"}"
	RET=$PIPESTATUS
	if [ ${RET} != 0 ] ; then
		aborta_padrao "$RET" "listar os databases (passo 1/2)"
	fi
}

# List databases to dump
yabt_list_databases()
{
	if [ -d "${YABT_OPENLDAP_CONF}" ] ; then
		list_databases_ids | while read DATABASE_ID ; do
				YABT_MSG_ERR="list databases"
				${SLAPCAT_CMD} -n${DATABASE_ID} | cat | head -n1 | cut -f2 -d' '
		done
	else
		YABT_MSG_ERR="list databases"
		grep ^suffix /etc/openldap/slapd.conf | sed 's/^suffix[ \t]*//g' | sed "s/,[ ]*/,/g" | sed 's/"//g'
	fi
	unset YABT_MSG_ERR
}

yabt_init()
{
	# Test if configuration file (ou dir) exists
	if [ -z "${YABT_OPENLDAP_CONF}" ] ; then
		yabt_abort "YABT_OPENLDAP_CONF setting undefined"
	elif [ ! -e "${YABT_OPENLDAP_CONF}" ] ; then
		yabt_abort "YABT_OPENLDAP_CONF (\"${YABT_OPENLDAP_CONF}\") must be point to valid file/directory"
	fi

	# Define linhas de comando baseado nas configuracoes carregadas
	if [ -d "${YABT_OPENLDAP_CONF}" ] ; then
		SLAPCAT_CMD="slapcat -F${YABT_OPENLDAP_CONF} "
	else
		SLAPCAT_CMD="slapcat -f${YABT_OPENLDAP_CONF} "
	fi
	
	YABT_DUMP_EXTENSION="ldif"	
}

yabt_dump_database()
{
	${SLAPCAT_CMD} -b $1
}

# Generic yabt run
. "$(dirname $0)/yabt.sh"
if [ $? != 0 ] ; then
	echo "environment initialization error" 1>&2
	exit 1
fi

exit 0
